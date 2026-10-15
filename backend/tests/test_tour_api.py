import asyncio

import httpx

from backend.app.tour_api import TourApiClient, TourApiError
from backend.app import main


def _response(items, total=None):
    return {
        "response": {
            "header": {"resultCode": "0000", "resultMsg": "OK"},
            "body": {
                "items": {"item": items},
                "totalCount": len(items) if total is None else total,
            },
        }
    }


def test_region_codes_are_looked_up_and_not_hardcoded():
    calls = []

    def respond(request):
        calls.append((request.url.path, dict(request.url.params)))
        path = request.url.path
        params = request.url.params
        if path.endswith("areaCode2") and "areaCode" not in params:
            return httpx.Response(200, json=_response([
                {"name": "경상북도", "code": "PROVINCE_FROM_API"}
            ]))
        if path.endswith("areaCode2"):
            assert params["areaCode"] == "PROVINCE_FROM_API"
            return httpx.Response(200, json=_response([
                {"name": "경산시", "code": "CITY_FROM_API"}
            ]))
        if path.endswith("areaBasedList2"):
            assert params["areaCode"] == "PROVINCE_FROM_API"
            assert params["sigunguCode"] == "CITY_FROM_API"
            return httpx.Response(200, json=_response([{
                "contentid": "123",
                "contenttypeid": "12",
                "title": "테스트 장소",
                "addr1": "경상북도 경산시 테스트로",
                "firstimage": "https://example.org/photo.jpg",
            }]))
        if path.endswith("detailCommon2"):
            return httpx.Response(200, json=_response([{
                "contentid": "123",
                "contenttypeid": "12",
                "title": "테스트 장소",
                "areacode": "PROVINCE_FROM_API",
                "sigungucode": "CITY_FROM_API",
                "overview": "<p>테스트 소개</p>",
            }]))
        if path.endswith("detailIntro2"):
            return httpx.Response(200, json=_response([{}]))
        raise AssertionError(path)

    client = TourApiClient("test-key", httpx.MockTransport(respond))

    async def run():
        places = await client.places(1, 20)
        repeated_places = await client.places(1, 20)
        detail = await client.detail("123")
        repeated_detail = await client.detail("123")
        return places, repeated_places, detail, repeated_detail

    places, repeated_places, detail, repeated_detail = asyncio.run(run())
    assert places["items"][0]["category"] == "관광지"
    assert repeated_places == places
    assert len([x for x in calls if x[0].endswith("areaBasedList2")]) == 1
    assert detail["overview"] == "테스트 소개"
    assert detail["opening_hours"] is None
    assert detail["fee"] is None
    assert repeated_detail == detail
    assert len([x for x in calls if x[0].endswith("detailCommon2")]) == 1
    assert len([x for x in calls if x[0].endswith("detailIntro2")]) == 1
    assert len([x for x in calls if x[0].endswith("areaCode2")]) == 2
    assert "test-key" not in str(places) + str(detail)


def test_missing_key_fails_without_an_upstream_call():
    client = TourApiClient(None)

    async def run():
        try:
            await client.places(1, 20)
        except TourApiError as exc:
            return exc
        raise AssertionError("missing key must fail")

    error = asyncio.run(run())
    assert error.code == "TOUR_API_KEY_MISSING"
    assert error.status_code == 503


def test_http_api_reports_missing_key_without_a_fake_list(monkeypatch):
    monkeypatch.setattr(main, "tour_api", TourApiClient(None))

    async def run():
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=main.app),
            base_url="http://testserver",
        ) as client:
            health = await client.get("/health")
            places = await client.get("/api/places")
            return health, places

    health, places = asyncio.run(run())
    assert health.json() == {"status": "ok", "tour_api_key_configured": False}
    assert places.status_code == 503
    assert places.json()["detail"]["code"] == "TOUR_API_KEY_MISSING"
