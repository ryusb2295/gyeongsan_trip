"""HTTP API used by the Flutter client; never sends the TourAPI key to it."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Path as PathParam, Query

from .tour_api import TourApiClient, TourApiError

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

app = FastAPI(title="경산 여행 API", version="0.1.0")
tour_api = TourApiClient(os.getenv("TOUR_API_KEY"))


def _raise_http(exc: TourApiError) -> None:
    raise HTTPException(
        status_code=exc.status_code,
        detail={"code": exc.code, "message": exc.message},
    ) from None


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "tour_api_key_configured": tour_api.has_key}


@app.get("/api/region/gyeongsan")
async def gyeongsan_region() -> dict:
    try:
        area_code, city_code = await tour_api.gyeongsan_codes()
    except TourApiError as exc:
        _raise_http(exc)
    return {
        "province": "경상북도",
        "city": "경산시",
        "area_code": area_code,
        "sigungu_code": city_code,
    }


@app.get("/api/places")
async def places(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
) -> dict:
    try:
        return await tour_api.places(page=page, limit=limit)
    except TourApiError as exc:
        _raise_http(exc)


@app.get("/api/places/{content_id}")
async def place_detail(
    content_id: str = PathParam(pattern=r"^[0-9]{1,20}$"),
) -> dict:
    try:
        return await tour_api.detail(content_id)
    except TourApiError as exc:
        _raise_http(exc)
