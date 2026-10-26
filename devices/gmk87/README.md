# Mechanical Keyboard GMK87

- ZUOYA GMK87 기계식 키보드의 장비 정보, 연결 방법, 키 매핑 및 설정 백업 관리 문서입니다.
- 제조사: ZUOYA
- 모델명: GMK87
- 연결 방식: USB-C 유선 / 2.4 GHz 무선 / Bluetooth
- 키 매핑 도구: VIA

## 기능

- **USB-C 유선 연결**: USB 케이블로 PC에 연결합니다.
- **2.4 GHz 무선 연결**: 전용 USB 수신기를 사용합니다.
- **Bluetooth 연결**: 최대 3개 장치 프로필(BT1, BT2, BT3)을 등록하고 전환할 수 있습니다.
- **키 매핑**: VIA 호환 JSON 정의 파일을 불러와 키 배치를 설정합니다.
- **설정 백업**: 제조사/배포처에서 제공한 JSON 파일을 원본 그대로 보관합니다.
- **LCD 화면 사용자 설정**: 제조사 또는 배포처가 제공하는 전용 도구와 호환 파일이 필요한 기능입니다.

## 디렉터리 구조

```text
gmk87/
├── README.md
└── backup/
    └── ZUOYA/
        ├── GMK87-2.4G.JSON
        └── GMK87-USB.JSON
```

- `README.md`: 장비 사양, 연결 방법, VIA 설정 및 참고 자료
- `backup/ZUOYA/GMK87-2.4G.JSON`: 2.4 GHz 모드용 VIA 키보드 정의 파일
- `backup/ZUOYA/GMK87-USB.JSON`: USB 유선 모드용 VIA 키보드 정의 파일


## 연결 방법

키보드 측면의 모드 스위치를 사용할 연결 방식에 맞게 설정합니다. 스위치의 실제 표기와 위치는 제품 리비전을 기준으로 확인하세요.

### USB-C 유선 연결

1. 모드 스위치를 USB 또는 Wired 위치로 설정합니다.
2. USB-C 케이블로 키보드와 PC를 연결합니다.
3. 화면 표시 및 운영체제의 키 입력 인식 여부를 확인합니다.

### 2.4 GHz 무선 연결

1. 모드 스위치를 2.4G 위치로 설정합니다.
2. 전용 USB 수신기를 PC에 연결합니다.
3. 키보드 화면의 2.4G 표시가 안정적으로 켜지는지 확인합니다.

일반적으로 출고 시 수신기와 페어링되어 있습니다. 연결이 끊겨 재페어링해야 하는 경우:

1. 키보드를 2.4G 모드로 설정합니다.
2. `Fn + R`을 3~5초간 길게 눌러 페어링 모드에 진입합니다.
3. 표시등이 깜박이는 동안 USB 수신기를 PC에 연결합니다.
4. 표시등의 깜박임이 멈추면 연결을 확인합니다.

### Bluetooth 연결

GMK87은 최대 3개의 Bluetooth 장치 프로필을 지원합니다.

| 프로필 | 페어링 진입 | 페어링된 장치로 전환 |
|---|---|---|
| BT1 | `Fn + Q` 3~5초 길게 누르기 | `Fn + Q` 짧게 누르기 |
| BT2 | `Fn + W` 3~5초 길게 누르기 | `Fn + W` 짧게 누르기 |
| BT3 | `Fn + E` 3~5초 길게 누르기 | `Fn + E` 짧게 누르기 |

페어링 절차:

1. 모드 스위치를 Bluetooth 또는 BT 위치로 설정합니다.
2. 연결할 프로필에 맞춰 `Fn + Q`, `Fn + W`, `Fn + E` 중 하나를 3~5초간 길게 누릅니다.
3. 키보드 화면에서 해당 Bluetooth 프로필 표시가 빠르게 깜박이는지 확인합니다.
4. PC, 태블릿 또는 휴대전화의 Bluetooth 설정을 열고 주변 기기를 검색합니다.
5. 해당 프로필의 기기 이름(예: `ZUOYA GMK87-1`, `ZUOYA GMK87-2`, `ZUOYA GMK87-3`)을 선택합니다.
6. 화면 표시의 깜박임이 멈추면 연결을 확인합니다.

이미 페어링된 장치로 전환할 때는 해당 프로필의 `Fn` 조합을 짧게 누릅니다. 기기 이름은 펌웨어/리비전에 따라 다를 수 있습니다.

## VIA 키 매핑 설정

- VIA 웹 애플리케이션: [https://usevia.app/](https://usevia.app/)
- VIA 공식 웹사이트: [https://caniusevia.com/](https://caniusevia.com/)
- VIA 데스크톱 릴리스: [https://github.com/WestBerryVIA/via-releases/releases](https://github.com/WestBerryVIA/via-releases/releases)

### 설정 절차

1. 가능하면 USB-C 케이블로 키보드를 PC에 연결하고 모드 스위치를 USB/Wired로 설정합니다.
2. VIA 웹 애플리케이션 또는 데스크톱 앱을 실행합니다.
3. 필요하면 VIA의 설정에서 디자인 탭 표시 옵션을 활성화합니다.
4. 디자인 탭에서 `GMK87-USB.JSON`을 불러옵니다. VIA 버전에 따라 메뉴 명칭이 다를 수 있습니다.
5. 키보드 레이아웃이 표시되는지 확인한 뒤 키 매핑을 변경합니다.
6. 변경한 키를 눌러 실제 입력이 적용되는지 확인합니다.

2.4 GHz 모드에서 VIA를 사용해야 하는 경우, 제조사 안내에 따라 `GMK87-2.4G.JSON`을 사용합니다. JSON 파일은 연결 모드와 PCB/펌웨어 리비전에 맞는 것을 선택해야 합니다.

## LCD 시간 설정 및 이미지 변경

LCD 시계의 시간 동기화와 사용자 이미지 변경은 VIA 키 매핑 설정과 별도로 디스플레이 설정 도구를 이용합니다.

- GMK87 Configurator: [https://codedgar.github.io/gmk87-node/](https://codedgar.github.io/gmk87-node/)
- GitHub 저장소: [https://github.com/codedgar/gmk87-node](https://github.com/codedgar/gmk87-node)
- 제조사 다운로드 페이지: [http://zuoya.top/qdxz_04161229_941](http://zuoya.top/qdxz_04161229_941)

### 시간 동기화

1. 키보드를 USB-C 케이블로 PC에 연결하고 USB/Wired 모드로 설정합니다.
2. GMK87 Configurator를 실행합니다.
3. 도구에서 `Time Sync` 또는 시간 동기화 기능을 실행합니다.
4. 키보드 LCD에 표시된 시간이 PC 시간과 일치하는지 확인합니다.

시간이 어긋나면 PC 운영체제의 시간이 맞는지 확인한 뒤 다시 동기화합니다. 도구 버전에 따라 메뉴 명칭과 절차가 달라질 수 있습니다.

### LCD 이미지 또는 GIF 변경

1. 키보드를 USB-C 케이블로 PC에 연결하고 USB/Wired 모드로 설정합니다.
2. GMK87 Configurator 또는 제조사에서 제공한 디스플레이 설정 도구를 실행합니다.
3. 업로드할 이미지 또는 GIF 파일을 선택합니다.
4. 지원되는 이미지 슬롯을 선택하고 업로드를 실행합니다.
5. 업로드가 완료될 때까지 연결을 유지합니다.
6. 키보드 LCD에서 해당 이미지가 표시되는지 확인합니다.

도구 및 펌웨어 버전에 따라 지원 파일 형식, 이미지 크기, 슬롯 수와 화면 전환 방법이 달라질 수 있으므로, 도구 화면과 해당 리비전의 안내를 기준으로 설정하세요. GMK87 Configurator의 사용법과 명령은 [프로젝트 문서](https://codedgar.github.io/gmk87-node/)를 참고합니다.

## 설정 백업 및 관리

### 순정 JSON 파일

다음 파일을 제조사 또는 배포처에서 받은 원본 그대로 보관합니다.

- `backup/ZUOYA/GMK87-2.4G.JSON`
- `backup/ZUOYA/GMK87-USB.JSON`

## 참고 자료

### 제조사

- ZUOYA 공식 홈페이지: [http://zuoya.top/](http://zuoya.top/)
- GMK87 제품 설명: [http://zuoya.top/productinfo/1332128.html](http://zuoya.top/productinfo/1332128.html)
- 제조사 다운로드 페이지: [http://zuoya.top/qdxz_04161229_941](http://zuoya.top/qdxz_04161229_941)

### VIA

- VIA 웹 애플리케이션: [https://usevia.app/](https://usevia.app/)
- VIA 공식 웹사이트: [https://caniusevia.com/](https://caniusevia.com/)
- VIA 데스크톱 릴리스: [https://github.com/WestBerryVIA/via-releases/releases](https://github.com/WestBerryVIA/via-releases/releases)

### 추가 참고 자료

- GMK87 사용 설명서 PDF: [https://ae01.alicdn.com/kf/S1f74ed34d51d4846a237a676f7d28a07Q.pdf](https://ae01.alicdn.com/kf/S1f74ed34d51d4846a237a676f7d28a07Q.pdf)
- GMK87 JSON 다운로드 안내(배포처): [https://mkb.gg/pages/download-center](https://mkb.gg/pages/download-center)
