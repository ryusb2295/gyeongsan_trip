# 경산 여행

Flutter 앱과 FastAPI 서버로 경산 관광정보를 탐색하고 장소를 코스 후보에 담는 프로젝트입니다. 관광정보는 한국관광공사 TourAPI에서 서버가 조회합니다. 지도, 자동 코스 추천, LLM은 아직 구현되지 않았습니다. 홈의 코스 카드는 화면 예시용 샘플입니다.

## 다른 Windows PC에서 실행

1. Git, VS Code, Flutter SDK, Android SDK와 Android 에뮬레이터, Python 3.11 이상을 준비합니다. Android Studio는 SDK·에뮬레이터 설치와 관리에만 사용해도 됩니다. `flutter doctor -v`로 설치를 확인하세요.
2. 저장소를 복제한 폴더에서 `flutter pub get`을 실행합니다.
3. [한국관광공사 국문 관광정보 서비스_GW](https://www.data.go.kr/data/15101578/openapi.do)의 인증키를 **새 PC에서** `backend/.env`에 설정합니다. 키는 GitHub에 올리지 않습니다.

```powershell
Copy-Item backend\.env.example backend\.env
# VS Code에서 backend\.env의 TOUR_API_KEY= 뒤에 발급받은 키를 입력하고 저장
python -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
backend\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000
```

4. 다른 터미널에서 에뮬레이터를 켠 뒤 `flutter devices`로 ID를 확인하고 `flutter run -d <에뮬레이터 ID>`를 실행합니다. 앱은 Android 에뮬레이터에서 PC 서버를 `http://10.0.2.2:8000`으로 찾습니다. 서버 상태는 `http://127.0.0.1:8000/health`에서 확인할 수 있습니다.

배포 서버를 사용할 때는 `flutter run --dart-define=API_BASE_URL=https://서버주소`처럼 주소를 주입합니다. iOS 빌드·배포에는 Mac과 Xcode가 필요합니다.

## 개발 확인

```powershell
flutter analyze
flutter test
python -m pytest backend\tests -q
```

백엔드 실행과 품질 조사 방법은 [backend/README.md](backend/README.md), 최근 조사 결과는 [backend/QUALITY_AUDIT.md](backend/QUALITY_AUDIT.md)에 있습니다. `backend/.env`, 가상환경, 빌드 산출물과 PC별 SDK 설정은 Git에서 제외합니다.
