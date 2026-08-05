# NAN 2026 제출 체크리스트

## 저장소

- [ ] GitHub 저장소 공개(Public) 전환
- [ ] `git status`에 제출할 변경사항이 남지 않도록 커밋
- [ ] 기존 `.git` 커밋 기록을 유지하고 squash/force-push하지 않음
- [ ] `lib/`, `android/`, `ios/`, `web/`, `test/`, `pubspec.yaml`, `pubspec.lock` 포함 확인
- [ ] `upload-keystore.jks`, `key.properties` 등 비공개 서명 정보가 추적되지 않는지 확인

## 품질 확인

- [ ] `flutter analyze --no-fatal-infos` 오류·경고 없이 통과
- [ ] `flutter test` 통과
- [ ] Android 7.0 이상 실제 기기에 APK 설치
- [ ] 비행기 모드에서 캐릭터 선택부터 한 경기 종료까지 플레이
- [ ] 로그인·결제·라이선스 입력 요구가 없는지 확인

## APK 배포

- [ ] 버전과 빌드 번호 확인 (`pubspec.yaml`)
- [ ] `v1.0.0` 같은 버전 태그 생성 및 push
- [ ] GitHub Actions의 `Android APK` workflow 통과 확인
- [ ] GitHub Release에 APK와 `.sha256` 파일이 첨부됐는지 확인
- [ ] 로그아웃/시크릿 창에서 Release URL과 APK 다운로드가 열리는지 확인
- [ ] 제출 폼에는 `.exe`가 아닌 APK 또는 Release 다운로드 링크 입력

## 제출 정보

- 앱 이름: `1:1 축구`
- 애플리케이션 ID: `com.proustudio.soccer_game`
- 버전: `1.0.0+4`
- 최소 Android: `7.0 (API 24)`
- 로그인/계정/결제: 없음
- 게임 실행 네트워크: 불필요
- 별도 유료 라이선스: 없음
