"""Server-side adapter for the Korea Tourism Organization KorService2 API."""

from __future__ import annotations

import asyncio
import html
import math
import re
import time
from urllib.parse import unquote, urlsplit

import httpx

BASE_URL = "https://apis.data.go.kr/B551011/KorService2"
SOURCE_NAME = "한국관광공사 TourAPI 국문 관광정보 서비스"
SOURCE_URL = "https://www.data.go.kr/data/15101578/openapi.do"

CONTENT_TYPES = {
    "12": "관광지",
    "14": "문화시설",
    "15": "축제·공연·행사",
    "25": "여행코스",
    "28": "레포츠",
    "32": "숙박",
    "38": "쇼핑",
    "39": "음식점",
}


class TourApiError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 502):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


def _item_list(payload: dict) -> list[dict]:
    body = payload.get("response", {}).get("body", {})
    items = body.get("items") or {}
    if not isinstance(items, dict):
        return []
    value = items.get("item") or []
    if isinstance(value, dict):
        return [value]
    return value if isinstance(value, list) else []


def _plain(value: object) -> str | None:
    if value is None:
        return None
    text = html.unescape(re.sub(r"<[^>]+>", " ", str(value)))
    text = " ".join(text.split())
    return text or None


def _image_url(value: object) -> str | None:
    if not value:
        return None
    url = str(value).strip()
    return url if urlsplit(url).scheme in {"http", "https"} else None


def _category(content_type_id: object) -> str:
    return CONTENT_TYPES.get(str(content_type_id or ""), "기타")


def _address(item: dict) -> str | None:
    return _plain(" ".join(str(item.get(key) or "") for key in ("addr1", "addr2")))


def _first_present(item: dict, keys: tuple[str, ...]) -> str | None:
    for key in keys:
        value = _plain(item.get(key))
        if value:
            return value
    return None


def _coordinate(item: dict) -> tuple[float, float] | None:
    try:
        longitude, latitude = float(item.get("mapx")), float(item.get("mapy"))
    except (TypeError, ValueError):
        return None
    if not (math.isfinite(longitude) and math.isfinite(latitude)):
        return None
    if not (-180 <= longitude <= 180 and -90 <= latitude <= 90):
        return None
    return None if longitude == 0 and latitude == 0 else (latitude, longitude)


def _place(item: dict) -> dict | None:
    content_id = str(item.get("contentid") or "").strip()
    title = _plain(item.get("title"))
    if not content_id or not title:
        return None
    coordinate = _coordinate(item)
    address = _address(item)
    flags = []
    if coordinate is None:
        flags.append("좌표 없음")
    if address and "경산시" not in address:
        flags.append("주소 위치 확인 필요")
    return {
        "id": content_id,
        "title": title,
        "category": _category(item.get("contenttypeid")),
        "content_type_id": str(item.get("contenttypeid") or ""),
        "address": address,
        "image_url": _image_url(item.get("firstimage")),
        "latitude": coordinate[0] if coordinate else None,
        "longitude": coordinate[1] if coordinate else None,
        "quality_flags": flags,
    }


class TourApiClient:
    def __init__(self, service_key: str | None, transport: httpx.AsyncBaseTransport | None = None):
        # The portal offers encoded and decoded keys. httpx encodes query values once.
        self._service_key = unquote(service_key.strip()) if service_key else None
        self._transport = transport
        self._region_cache: tuple[float, tuple[str, str]] | None = None
        self._region_lock = asyncio.Lock()
        # Short-lived, process-local cache of app-ready detail data only.
        self._detail_cache: dict[str, tuple[float, dict]] = {}
        self._detail_lock = asyncio.Lock()
        self._last_detail_request = 0.0
        self._places_cache: dict[tuple[int, int], tuple[float, dict]] = {}
        self._places_lock = asyncio.Lock()

    @property
    def has_key(self) -> bool:
        return bool(self._service_key)

    async def _get(self, endpoint: str, params: dict[str, object] | None = None) -> dict:
        if not self._service_key:
            raise TourApiError(
                "TOUR_API_KEY_MISSING",
                "TourAPI 인증키가 설정되지 않았어요.",
                503,
            )
        query: dict[str, object] = {
            "serviceKey": self._service_key,
            "MobileOS": "ETC",
            "MobileApp": "GyeongsanTrip",
            "_type": "json",
        }
        query.update(params or {})
        try:
            async with httpx.AsyncClient(
                timeout=12, transport=self._transport, follow_redirects=False
            ) as client:
                response = await client.get(f"{BASE_URL}/{endpoint}", params=query)
                response.raise_for_status()
                payload = response.json()
        except httpx.TimeoutException as exc:
            raise TourApiError("TOUR_API_TIMEOUT", "관광정보 응답이 지연되고 있어요.") from exc
        except (httpx.HTTPError, ValueError) as exc:
            # Do not expose request URLs or exception text: they can contain the key.
            raise TourApiError("TOUR_API_UNAVAILABLE", "관광정보를 가져오지 못했어요.") from exc
        if not isinstance(payload, dict):
            raise TourApiError("TOUR_API_BAD_RESPONSE", "관광정보 응답 형식이 올바르지 않아요.")
        header = payload.get("response", {}).get("header", {})
        if str(header.get("resultCode", "")) not in {"0000", "00"}:
            raise TourApiError("TOUR_API_REJECTED", "관광정보 서비스가 요청을 처리하지 못했어요.")
        return payload

    async def gyeongsan_codes(self) -> tuple[str, str]:
        cached = self._region_cache
        if cached and cached[0] > time.monotonic():
            return cached[1]
        async with self._region_lock:
            cached = self._region_cache
            if cached and cached[0] > time.monotonic():
                return cached[1]
            provinces = _item_list(
                await self._get("areaCode2", {"numOfRows": 100, "pageNo": 1})
            )
            province = next((x for x in provinces if _plain(x.get("name")) == "경상북도"), None)
            if not province or not province.get("code"):
                raise TourApiError("REGION_NOT_FOUND", "TourAPI에서 경상북도 코드를 찾지 못했어요.")
            area_code = str(province["code"])
            cities = _item_list(
                await self._get(
                    "areaCode2",
                    {"areaCode": area_code, "numOfRows": 100, "pageNo": 1},
                )
            )
            city = next((x for x in cities if _plain(x.get("name")) == "경산시"), None)
            if not city or not city.get("code"):
                raise TourApiError("REGION_NOT_FOUND", "TourAPI에서 경산시 코드를 찾지 못했어요.")
            codes = (area_code, str(city["code"]))
            self._region_cache = (time.monotonic() + 3600, codes)
            return codes

    async def places(self, page: int, limit: int) -> dict:
        cache_key = (page, limit)
        cached = self._places_cache.get(cache_key)
        if cached and cached[0] > time.monotonic():
            return cached[1]
        async with self._places_lock:
            cached = self._places_cache.get(cache_key)
            if cached and cached[0] > time.monotonic():
                return cached[1]
            result = await self._fetch_places(page, limit)
            self._places_cache[cache_key] = (time.monotonic() + 300, result)
            return result

    async def _fetch_places(self, page: int, limit: int) -> dict:
        area_code, city_code = await self.gyeongsan_codes()
        payload = await self._get(
            "areaBasedList2",
            {
                "areaCode": area_code,
                "sigunguCode": city_code,
                "pageNo": page,
                "numOfRows": limit,
            },
        )
        body = payload.get("response", {}).get("body", {})
        places = [place for item in _item_list(payload) if (place := _place(item))]
        return {
            "items": places,
            "page": page,
            "total_count": int(body.get("totalCount") or 0),
            "source": SOURCE_NAME,
        }

    async def detail(self, content_id: str) -> dict:
        cached = self._detail_cache.get(content_id)
        if cached and cached[0] > time.monotonic():
            return cached[1]
        async with self._detail_lock:
            cached = self._detail_cache.get(content_id)
            if cached and cached[0] > time.monotonic():
                return cached[1]
            detail = await self._fetch_detail(content_id)
            self._detail_cache[content_id] = (time.monotonic() + 300, detail)
            return detail

    async def _detail_get(self, endpoint: str, params: dict[str, object]) -> dict:
        delay = 0.5 - (time.monotonic() - self._last_detail_request)
        if delay > 0:
            await asyncio.sleep(delay)
        self._last_detail_request = time.monotonic()
        return await self._get(endpoint, params)

    async def _fetch_detail(self, content_id: str) -> dict:
        area_code, city_code = await self.gyeongsan_codes()
        common_items = _item_list(await self._detail_get("detailCommon2", {"contentId": content_id}))
        if not common_items:
            raise TourApiError("PLACE_NOT_FOUND", "장소 정보를 찾지 못했어요.", 404)
        item = common_items[0]
        if str(item.get("areacode") or "") != area_code or str(
            item.get("sigungucode") or ""
        ) != city_code:
            raise TourApiError("PLACE_NOT_FOUND", "경산시 장소 정보를 찾지 못했어요.", 404)
        content_type_id = item.get("contenttypeid")
        intro: dict = {}
        if content_type_id:
            intro_items = _item_list(
                await self._detail_get(
                    "detailIntro2",
                    {"contentId": content_id, "contentTypeId": content_type_id},
                )
            )
            if intro_items:
                intro = intro_items[0]
        place = _place(item)
        if not place:
            raise TourApiError("PLACE_NOT_FOUND", "장소 정보를 찾지 못했어요.", 404)
        return {
            **place,
            "overview": _plain(item.get("overview")),
            "phone": _first_present(item, ("tel",)) or _first_present(intro, ("infocenter", "infocenterculture", "infocenterfood")),
            "opening_hours": _first_present(
                intro,
                ("usetime", "usetimeculture", "usetimeleports", "opentimefood", "opentime", "checkintime"),
            ),
            "closed_days": _first_present(
                intro,
                ("restdate", "restdateculture", "restdateleports", "restdatefood", "restdateindoor", "restdateoutdoor"),
            ),
            "fee": _first_present(intro, ("usefee", "usefeeleports", "usefeefood")),
            "source": SOURCE_NAME,
            "source_url": SOURCE_URL,
        }
