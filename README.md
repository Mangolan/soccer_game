# 1:1 축구

동물 캐릭터를 선택해 AI와 대결하는 Flutter 기반 1대1 축구 게임입니다.
로그인이나 유료 라이선스 없이 플레이할 수 있습니다.

## 심사용 Android 앱

GitHub Releases에 첨부된 `app-release.apk`를 Android 기기에 내려받아
설치하면 바로 실행할 수 있습니다. Android의 보안 안내가 표시되면 해당 브라우저의
`출처를 알 수 없는 앱 설치`를 한 번 허용해야 합니다.

- 애플리케이션 ID: `com.proustudio.soccer_game`
- 앱 버전: `1.0.0+4`
- 지원 버전: Android 7.0(API 24) 이상
- 로그인 및 별도 계정: 필요 없음
- 네트워크: Firebase Analytics 전송 외에 게임 진행에는 필요 없음

## 플레이 방법

1. 동물 캐릭터를 선택합니다.
2. AI 난이도를 선택합니다.
3. 경기 화면 위쪽의 시작 버튼을 누릅니다.
4. 왼쪽/오른쪽 방향 버튼으로 이동하고 점프 버튼으로 점프합니다.
5. 먼저 10점을 획득하면 승리합니다.

## 소스 코드 실행

Flutter SDK와 Android 개발 환경이 필요합니다.

```bash
flutter pub get
flutter run
```

릴리스 APK는 다음 명령으로 생성합니다. 공개 저장소에는 서명 키와
`android/key.properties`를 포함하지 않습니다.

```bash
flutter build apk --release
```

## 주요 소스

- `lib/main.dart`: 앱 진입점
- `lib/player_selection_screen.dart`: 캐릭터 선택 화면
- `lib/difficulty_selection_screen.dart`: AI 난이도 선택 화면
- `lib/game_screen.dart`: 게임 화면 구성
- `lib/game/game_widget.dart`: 게임 렌더링 및 입력 처리
- `lib/game/game_logic.dart`: 물리, 충돌, 득점 및 AI 로직
- `lib/game/adaptive_ai.dart`: 20초 플레이 패턴 분석과 적응형 AI 전략
- `docs/adaptive_ai.md`: 적응형 AI 설계·A/B 비교 문서
- `lib/animal_player.dart`: 동물 캐릭터 데이터와 렌더링

## 주요 의존성

- `shared_preferences`: 마지막 캐릭터 선택과 진행 상태 저장
- `url_launcher`: 개인정보 처리방침 열기
- `firebase_core`, `firebase_analytics`: 익명 사용 통계

개인정보 처리방침은 저장소의 `privacy_policy.html`에서 확인할 수 있습니다.
