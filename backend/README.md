# 경산 여행 API

한국관광공사 [국문 관광정보 서비스_GW](https://www.data.go.kr/data/15101578/openapi.do)의 `KorService2`를 서버에서 호출합니다. 앱에는 인증키를 전달하지 않습니다.

## 인증키 발급

1. 공공데이터포털에 로그인하고 위 서비스의 **활용신청**을 진행합니다. 개발계정은 공식 페이지 기준 자동승인입니다.
2. 마이페이지에서 발급된 **일반 인증키(Decoding)**를 확인합니다. 키를 채팅이나 저장소에 올리지 마세요.
3. `backend/.env.example`을 `backend/.env`로 복사하고, `TOUR_API_KEY=` 뒤에 본인의 키를 로컬에서 입력합니다. `.env`는 Git 제외 대상입니다.

## Windows / VS Code 실행

프로젝트 루트의 PowerShell 터미널에서:

```powershell
python -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
Copy-Item backend\.env.example backend\.env
# VS Code에서 backend\.env를 열어 인증키를 입력한 뒤 저장
backend\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000
```

이미 `TOUR_API_KEY` 환경변수를 설정했다면 `.env` 파일은 생략해도 됩니다. 키를 추가하거나 변경한 후에는 서버를 재시작하세요. 확인용 주소는 `http://127.0.0.1:8000/health`, `http://127.0.0.1:8000/api/region/gyeongsan`, `http://127.0.0.1:8000/api/places`입니다. 키가 없으면 장소 API는 503을 반환합니다.

Android 에뮬레이터의 앱은 기본적으로 PC 서버에 `http://10.0.2.2:8000`으로 접속합니다. VS Code에서 Flutter를 실행하거나 `flutter run -d emulator-5554`를 사용하세요. 배포 서버로 바꿀 때는 앱 코드 대신 `flutter run --dart-define=API_BASE_URL=https://your-server.example` 또는 빌드 명령의 같은 옵션을 사용합니다. 실제 배포 URL에는 HTTPS를 사용하세요.

서버는 `areaCode2`에서 경상북도와 경산시 코드를 순서대로 조회하며, 조회가 끝나기 전에는 코드 값을 가정하지 않습니다. `areaBasedList2`로 목록을, `detailCommon2`와 `detailIntro2`로 상세 정보를 가져옵니다. 인증키가 없을 때는 실제 API 응답을 검증할 수 없습니다.

키를 설정하고 서버를 다시 띄운 뒤 `http://127.0.0.1:8000/api/region/gyeongsan`에서 실제 조회된 지역 코드를 확인하세요. 이어 `/api/places`에서 장소 목록을 확인하고, 그 응답의 `id`를 `/api/places/{id}`에 넣어 상세정보를 확인할 수 있습니다. 그 다음 에뮬레이터에서 **둘러보기**를 다시 시도하세요. 키가 없는 동안에는 샘플 장소를 실제 데이터인 것처럼 반환하지 않습니다.

백엔드 모의 응답 테스트는 프로젝트 루트에서 `python -m pytest backend\tests -q`로 실행합니다.

## 데이터 품질과 캐시

실제 조회 결과는 [QUALITY_AUDIT.md](QUALITY_AUDIT.md)에 정리했습니다. 다시 조사하려면 프로젝트 루트에서 `python backend\audit_quality.py`를 실행하세요. 이 명령은 전체 목록과 상세를 순차 호출하므로 개발계정 호출 한도를 사용합니다. 원본 응답은 조사 프로세스의 메모리에서만 재사용하며 출력하거나 파일로 저장하지 않습니다. 목록과 상세의 앱용 정규화 결과는 동일 서버 프로세스에서 5분간 메모리 캐시됩니다.
