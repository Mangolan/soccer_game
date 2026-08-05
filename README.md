# 1:1 축구 — NAN 2026 출품작

동물 캐릭터로 적응형 AI와 대결하는 Flutter 기반 모바일 1대1 축구 게임입니다.
로그인, 결제, 유료 라이선스, 네트워크 연결 없이 모든 게임 기능을 이용할 수 있습니다.

## 심사위원용 바로 실행

- Android APK: [GitHub Releases 최신 버전](https://github.com/Mangolan/soccer_game/releases/latest)
- 전체 소스: [이 저장소](https://github.com/Mangolan/soccer_game)
- 제출 파일: `soccer-game-1.0.0+4.apk` (PC 실행 파일은 제출하지 않음)
- 지원 기기: Android 7.0(API 24) 이상
- 계정/로그인/결제: 필요 없음
- 네트워크/서버: 필요 없음
- 사용자 승인 권한: 없음(카메라·마이크·위치·저장소 등 미사용)

APK를 내려받아 설치하면 바로 실행됩니다. Android가 보안 안내를 표시하면 APK를
내려받은 브라우저 또는 파일 관리자의 `출처를 알 수 없는 앱 설치` 권한을 한 번
허용해 주세요.

> Releases가 비어 있다면 아래의 `소스에서 APK 빌드` 절차로 동일한 APK를 만들 수
> 있습니다. 실제 제출 전에는 `docs/SUBMISSION_CHECKLIST.md`를 확인해 주세요.

## 플레이 방법

1. 동물 캐릭터를 선택합니다.
2. AI 난이도를 선택합니다.
3. 경기 화면 위쪽의 시작 버튼을 누릅니다.
4. 왼쪽/오른쪽 버튼으로 이동하고 점프 버튼으로 점프합니다.
5. 먼저 10점을 얻으면 승리합니다.

## AI 기능

적응형 AI는 경기 중 최근 20초의 플레이 패턴을 기기 안에서 분석합니다. 전진 성향,
점프 빈도, 공 접근 방식 등에 따라 수비·압박·공격 전략을 조절합니다. 플레이 데이터는
외부 서버로 전송되지 않습니다. 설계 및 A/B 비교는 `docs/adaptive_ai.md`에 설명되어
있습니다.

## 소스에서 APK 빌드

Flutter stable SDK와 Android SDK가 필요합니다.

```bash
flutter pub get
flutter test
flutter build apk --release
```

결과물은 `build/app/outputs/flutter-apk/app-release.apk`에 생성됩니다. 공개 저장소에는
개인 서명 키를 올리지 않습니다. `android/key.properties`가 없는 공개 저장소 복제본은
심사용 설치가 가능하도록 Android의 기본 개발 키로 release 빌드에 서명합니다. Play
Store 배포 시에는 본인 소유의 비공개 release 키를 사용해야 합니다.

태그(예: `v1.0.0`)를 push하면 `.github/workflows/android-apk.yml`이 테스트와 빌드를
수행하고 APK 및 SHA-256 파일을 GitHub Release에 자동 첨부합니다.

## 소스 구조

- `lib/`: 앱 화면, 게임 렌더링, 물리·충돌·득점, 적응형 AI 전체 소스
- `android/`, `ios/`, `web/`: 모바일 및 웹 플랫폼 프로젝트
- `test/`: 게임 로직, AI 행동, 위젯 테스트
- `docs/adaptive_ai.md`: 적응형 AI 설계와 실험 문서
- `docs/SUBMISSION_CHECKLIST.md`: 출품 직전 확인표
- `privacy_policy.html`: 개인정보처리방침

## 실행 및 오픈 소스 고지

게임 실행에는 별도 라이선스 키나 유료 라이선스가 필요하지 않습니다. 사용한 패키지는
모두 별도 구매가 필요 없는 오픈 소스이며, 자세한 고지는
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)에 정리되어 있습니다.
