"""Inspect TourAPI data without storing raw responses or exposing the service key."""

from __future__ import annotations

import asyncio
import json
import math
import statistics
import time
from collections import Counter

from dotenv import dotenv_values

from app.tour_api import TourApiClient, TourApiError, _first_present, _item_list, _plain


def coordinates(item: dict) -> tuple[float, float] | None:
    try:
        longitude = float(item.get("mapx"))
        latitude = float(item.get("mapy"))
    except (TypeError, ValueError):
        return None
    if not (math.isfinite(longitude) and math.isfinite(latitude)):
        return None
    if not (-180 <= longitude <= 180 and -90 <= latitude <= 90):
        return None
    if longitude == 0 and latitude == 0:
        return None
    return latitude, longitude


def distance_km(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat1, lon1 = map(math.radians, a)
    lat2, lon2 = map(math.radians, b)
    angle = 2 * math.asin(
        math.sqrt(math.sin((lat2 - lat1) / 2) ** 2 +
                  math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2)
    )
    return 6371 * angle


class AuditClient(TourApiClient):
    def __init__(self, key: str | None):
        super().__init__(key)
        self._last_request = 0.0
        self._responses: dict[tuple, dict] = {}
        self.requests = 0
        self.cache_hits = 0

    async def _get(self, endpoint: str, params: dict | None = None) -> dict:
        cache_key = (endpoint, tuple(sorted((params or {}).items())))
        if cache_key in self._responses:
            self.cache_hits += 1
            return self._responses[cache_key]
        delay = 0.5 - (time.monotonic() - self._last_request)
        if delay > 0:
            await asyncio.sleep(delay)
        self._last_request = time.monotonic()
        payload = await super()._get(endpoint, params)
        self.requests += 1
        self._responses[cache_key] = payload
        return payload


async def audit() -> dict:
    key = dotenv_values("backend/.env").get("TOUR_API_KEY")
    client = AuditClient(key)
    area_code, city_code = await client.gyeongsan_codes()
    pages: list[dict] = []
    page_number = 1
    total = None
    while total is None or len(pages) < total:
        payload = await client._get("areaBasedList2", {
            "areaCode": area_code, "sigunguCode": city_code,
            "numOfRows": 20, "pageNo": page_number,
        })
        if total is None:
            total = int(payload["response"]["body"].get("totalCount") or 0)
        page_items = _item_list(payload)
        if not page_items:
            break
        pages.extend(page_items)
        page_number += 1
        if page_number > 20:
            raise RuntimeError("Unexpected page count")

    ids = [str(item.get("contentid") or "") for item in pages]
    locations = [coordinates(item) for item in pages]
    known = [point for point in locations if point]
    median = (
        statistics.median(point[0] for point in known),
        statistics.median(point[1] for point in known),
    ) if known else None
    categories = Counter(str(item.get("contenttypeid") or "unknown") for item in pages)
    photo = sum(bool(item.get("firstimage")) for item in pages)
    address = sum(bool(_plain(item.get("addr1"))) for item in pages)
    geocoded = len(known)
    overview = hours = closed_days = fee = 0
    common_success = intro_success = 0
    failed: list[dict] = []
    flagged: list[dict] = []
    for item, point in zip(pages, locations):
        content_id = str(item.get("contentid") or "")
        title = _plain(item.get("title")) or "이름 없음"
        flags = []
        if point is None:
            flags.append("좌표 없음/유효하지 않음")
        elif median and distance_km(point, median) > 30:
            flags.append("좌표 중심에서 30km 초과: 경산 경계 확인 필요")
        if _plain(item.get("addr1")) and "경산시" not in str(item.get("addr1")):
            flags.append("주소의 시군구 불일치: 확인 필요")
        if flags:
            flagged.append({"id": content_id, "title": title, "reasons": flags})
        try:
            common = _item_list(await client._get("detailCommon2", {"contentId": content_id}))
            if common:
                common_success += 1
                overview += bool(_plain(common[0].get("overview")))
            content_type = item.get("contenttypeid")
            if content_type:
                intro = _item_list(await client._get("detailIntro2", {
                    "contentId": content_id, "contentTypeId": content_type,
                }))
                if intro:
                    intro_success += 1
                    fields = intro[0]
                    hours += bool(_first_present(fields, (
                        "usetime", "usetimeculture", "usetimeleports",
                        "opentimefood", "opentime", "checkintime",
                    )))
                    closed_days += bool(_first_present(fields, (
                        "restdate", "restdateculture", "restdateleports",
                        "restdatefood", "restdateindoor", "restdateoutdoor",
                    )))
                    fee += bool(_first_present(fields, (
                        "usefee", "usefeeleports", "usefeefood",
                    )))
        except TourApiError as exc:
            failed.append({"id": content_id, "code": exc.code})

    return {
        "region_codes": {"area": area_code, "sigungu": city_code},
        "reported_total": total, "retrieved": len(pages),
        "unique_ids": len(set(ids)), "pages": page_number - 1,
        "content_types": dict(sorted(categories.items())),
        "photo": {"present": photo, "missing": len(pages) - photo},
        "coordinates": {"present": geocoded, "missing_or_invalid": len(pages) - geocoded},
        "address": {"present": address, "missing": len(pages) - address},
        "overview": {"present": overview, "missing_or_unverified": len(pages) - overview},
        "opening_hours": {"present": hours, "missing_or_unverified": len(pages) - hours},
        "closed_days": {"present": closed_days, "missing_or_unverified": len(pages) - closed_days},
        "fee": {"present": fee, "missing_or_unverified": len(pages) - fee},
        "detail_common_success": common_success,
        "detail_intro_success": intro_success,
        "detail_failures": failed,
        "flagged_places": flagged,
        "median_coordinate": median,
        "upstream_requests": client.requests,
        "in_memory_cache_hits": client.cache_hits,
    }


if __name__ == "__main__":
    try:
        print(json.dumps(asyncio.run(audit()), ensure_ascii=True))
    except TourApiError as exc:
        print(json.dumps({"error_code": exc.code, "message": exc.message}, ensure_ascii=True))
