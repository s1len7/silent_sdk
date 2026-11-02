# assets

장비/스크립트에서 공통으로 사용하는 정적 자산(아이콘, 오디오, 폰트, UI 요소)

## 구조
- `icons/` - 아이콘
- `audio/` - 효과음/알림음
- `fonts/` - 폰트
- `ui/` - UI 요소/이미지


## TODO
  - 프로젝터 화면 테스트 (강의 전 점검: 화면 잘림·비율, 초점, 키스톤, 색, 밝은/어두운 회색 구분)
    - 테스트 패턴 이미지 (SVG라 어떤 해상도로도 깨끗하게 확대, `ui/`에 둘 것)
      - [SMPTE Color Bars](https://commons.wikimedia.org/wiki/File:SMPTE_Color_Bars.svg) (방송용 컬러 바, 퍼블릭 도메인)
      - [Philips PM5544](https://commons.wikimedia.org/wiki/File:Philips_PM5544.svg) (TV 화면 조정 시간의 원형 테스트 카드 재작도판, GFDL·CC BY-SA 3.0·CC BY 2.5 중 선택, CC BY 2.5로 쓰면 출처 표시만 하면 됨)
    - 웹 테스트 페이지 (설치 없이 강의장 PC 브라우저에서 바로, [Lagom LCD test](http://www.lagom.nl/lcd-test/), 무료 사용, 오픈소스 아님)
      - [contrast](http://www.lagom.nl/lcd-test/contrast.php) (색·밝기 단계 구분)
      - [black level](http://www.lagom.nl/lcd-test/black.php) (어두운 회색 구분)
      - [white saturation](http://www.lagom.nl/lcd-test/white.php) (밝은 회색 구분)
      - [sharpness](http://www.lagom.nl/lcd-test/sharpness.php) (선명도)
    - 데스크톱 도구
      - [screentest](https://github.com/TobiX/screentest) (Linux GTK, 소개 페이지 기준 GPL-2.0, GitHub에서는 라이선스가 자동 판별되지 않아 확인 필요)


- IT 강의용 자산 (새로 만들기보다 기존 오픈소스·무료 자산을 먼저 쓰고, Windows·Linux 모두 되는 웹·크로스플랫폼 도구를 우선함)
  - 쉬는 시간 시계·타이머
    - 요구: 슬라이드를 가리지 않는 반투명 창, 현재 시각 기본 표시, 쉬는 시간(분) 또는 종료 시각을 넣으면 종료 예정 시각·남은 시간 표시, 깔끔한 디자인
    - 후보: 
      - [PresentationClock](https://presentclock.sourceforge.net/) (Java, 슬라이드 위에 항상 보이는 시계·카운트다운, 라이선스 확인 필요),
      - [Clocki](https://github.com/MasihMoafi/clocki) (항상 위 HUD 시계, 저장소에 라이선스 없음 → 그대로는 못 씀)
      - opensource DeepHUD
    - 요구를 모두 만족하는 기존 오픈소스는 아직 못 찾음, 후보를 시험해 보고 부족하면 직접 구현 검토
  - 쉬는 시간 음악 (졸리거나 시끄럽지 않은 곡, 내려받은 곡은 라이선스·출처와 함께 `audio/`에 둘 것)
    - Kevin MacLeod ([incompetech](https://incompetech.com/music/royalty-free/music.html), CC BY 4.0, 쉬는 시간 화면에 크레딧 표시 필수: `"<제목>" Kevin MacLeod (incompetech.com) Licensed under Creative Commons: By Attribution 4.0 License`)
      - 내려받기: `https://incompetech.com/music/royalty-free/mp3-royaltyfree/<제목>.mp3`
      - Wallpaper (3:40, 밝고 편안함)
      - Carefree (3:25, 밝고 편안함, `audio/`에 저장함)
      - Easy Lemon (2:06, 밝고 편안함)
      - Local Forecast - Elevator (3:09, 밝고 편안함)
      - Airport Lounge (5:08, 라운지)
      - Lobby Time (3:13, 라운지)
      - Bossa Antigua (4:43, 보사노바)
      - Jazz Brunch (5:23, 재즈)
      - Laid Back Guitars (4:04, 기타)
      - Gymnopedie No. 1 (3:07, 잔잔한 피아노, Satie 편곡)
      - Monkeys Spinning Monkeys (2:05, 쉬는 시간 끝 알림용 경쾌한 곡, TikTok에서 가장 많이 쓰인 곡 중 하나, `audio/`에 저장함)
    - Pixabay (Pixabay Content License, 출처 표시 불필요, 강의장 공개 재생 조건은 [약관 본문](https://pixabay.com/service/terms/) 확인 필요)
      - [Good Night - Lofi Cozy Chill Music](https://pixabay.com/music/beats-good-night-lofi-cozy-chill-music-160166/) (FASSounds, 2:27)
      - [Once In Paris](https://pixabay.com/music/beats-once-in-paris-168895/) (Pumpupthemind, 2:12)
    - 기타 CC0
      - [Open Goldberg Variations](https://opengoldbergvariations.org/) (Kimiko Ishizaka 피아노 연주, Aria 등 잔잔한 곡, [Bandcamp](https://kimikoishizaka.bandcamp.com/album/j-s-bach-open-goldberg-variations-bwv-988-piano)에서 무료 내려받기 가능)
      - [lofi hip hop loop](https://opengameart.org/content/lofi-hip-hop-loop) (OpenGameArt)
  - 키 입력·마우스 동작 표시 (실습 시연)
    - [keyviz](https://github.com/mulaRahul/keyviz) (GPL-3.0, 최신 2.1.1 배포판은 Windows·macOS만)
    - screenkey 계열 (Linux, 확인 필요)
  - 화면 판서
    - [Gromit-MPX](https://github.com/bk138/gromit-mpx) (GPL-2.0, Linux)
    - [OpenBoard](https://github.com/OpenBoard-org/OpenBoard) (GPL-3.0, Windows·Linux·macOS 화이트보드)
    - [Excalidraw](https://github.com/excalidraw/excalidraw) (MIT, 웹 화이트보드)
  - 청중 참여
    - [Claper](https://github.com/ClaperCo/Claper) (AGPL-3.0, 투표·Q&A, 자체 호스팅)
    - [ClassQuiz](https://github.com/mawoka-myblock/ClassQuiz) (MPL-2.0, 퀴즈, Kahoot 대안)
  - 강의 자료 (마크다운·웹 슬라이드)
    - [reveal.js](https://github.com/hakimel/reveal.js) (MIT)
    - [Marp CLI](https://github.com/marp-team/marp-cli) (MIT)
  - 휴식 알림 (강사 본인용)
    - [BreakTimer](https://github.com/tom-james-watson/breaktimer-app) (GPL-3.0)
  - Wi-Fi 연결 QR 코드 (수강생이 강의장 Wi-Fi에 바로 접속)
    - [wifi-card](https://github.com/bndw/wifi-card) (MIT, 웹 [wificard.io](https://wificard.io), 인쇄용 QR 카드, 공식 Docker 이미지 있음)
    - [qifi](https://github.com/evgeni/qifi) (MIT, 순수 JS 생성기)
    - 비밀번호를 서버로 보내지 않는지 공식 문서에 설명이 없음 → 소스 확인 또는 자체 호스팅해서 쓸 것
  - 강의 자료 URL 배포용 단축 URL (자체 호스팅)
    - [YOURLS](https://github.com/YOURLS/YOURLS) (MIT, PHP·MySQL, 가장 널리 쓰임, QR은 플러그인)
    - [Kutt](https://github.com/thedevs-network/kutt) (MIT, 현대적인 UI)
    - [Shlink](https://github.com/shlinkio/shlink) (MIT, 공식 Docker 이미지·웹 클라이언트, QR 지원 여부 확인 필요)
    - 외부 수강생이 쓰려면 인터넷에서 접속할 수 있어야 함 (NAS에 둘 경우 nginx-proxy-manager로 공개 설정 필요)
