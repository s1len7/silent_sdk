# SAM4S TITAN-S260

- 제조사: [신흥정밀](https://www.sam4s.com/)
- 모델명: [TITAN-S260](https://www.sam4s.com/kor/products/KCA03-3)
- [매뉴얼, 드라이버, 유틸리티](https://www.sam4s.com/kor/support/download)


## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/titan-s260/main/setup.ps1 | iex
```


### Windows 10 IoT LTSC

- 정품 키 인증: [scripts/activate-win10-iot.cmd](scripts/activate-win10-iot.cmd) (펌웨어 OEM 키 자동 사용, 없으면 입력)

- https://massgrave.dev/ 참고해서 인증 스크립트 실행
```powershell
irm https://get.activated.win | iex
```


### ZoomIt

- Setup: [scripts/setup-zoomit.ps1](scripts/setup-zoomit.ps1)


### PowerToys

- Setup: [scripts/setup-powertoys.ps1](scripts/setup-powertoys.ps1) (최신 버전)


### Microsoft PC Manager

- Setup: [scripts/setup-pcmanager.ps1](scripts/setup-pcmanager.ps1) (winget으로 Store 앱 설치, winget 없으면 먼저 설치)


### 저사양 최적화

- Setup: [scripts/setup-performance.ps1](scripts/setup-performance.ps1) (적용 후 재부팅)
  1. 시각 효과 최적 성능 (투명·애니메이션 끄기, 단색 배경)
  2. Windows Search 인덱싱 끄기
  3. SysMain(Superfetch) 끄기
  4. 원격 분석(DiagTrack) 끄기
  5. 전원: 고성능, 화면 끄기·절전·USB 절전 해제
  6. 최대 절전 끄기 (hiberfil.sys 삭제)




