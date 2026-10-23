# SAM4S TITAN-S260

- 제조사: [신흥정밀](https://www.sam4s.com/)
- 모델명: [TITAN-S260](https://www.sam4s.com/kor/products/KCA03-3)
  - [다운로드(드라이버, 유틸리티, 매뉴얼)](https://www.sam4s.com/kor/support/download?model=TITAN-S2xx)
  - [매뉴얼](https://www.dropbox.com/scl/fi/1iu9m63el71y9zdk1cv3r/TITAN-S-E-Manual.pdf?rlkey=um6f6wkzlw6l77a8am33ak6ho&st=0hsry8z0&dl=0)
  - [리플릿](https://www.dropbox.com/scl/fi/8hvsh2klbl20oyw6u9w63/TITAN-S_Series_Leaflet-KOR.pdf?rlkey=nzi4lrko4q5vkhm3akgfb9hnv&st=46cz7d3u&dl=0)

| 항목 | 사양 |
| --- | --- |
| CPU | Intel Celeron N3160 (4코어, 1.60GHz / 최대 2.24GHz) |
| RAM | DDR3L SODIMM 1슬롯 (최대 8GB) |
| SSD | 2.5" SATA SSD/HDD, M.2 SSD (64/128/256GB) |
| 디스플레이 | 15" LED LCD 1024 x 768 |
| 터치 | PCAP 또는 5선 저항막 |
| 포트 | USB 2.0 x4, USB 3.0 x2, COM x4, LAN 1Gb, VGA, 금전함, Line-out |
| 전원 | DC 12V 5A (60W) |


## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/titan-s260/setup.ps1 | iex
```

- 실패한 단계가 있어도 나머지 단계는 계속 진행하고, 끝에 단계별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 단계는 SKIP하고, 실패했거나 안 된 단계만 다시 진행함 (단계별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `C:\silent_sdk\logs\titan-s260-<시각>\` (`setup.log` 전체 실행 기록, `*-install.log` 설치 프로그램 로그)


### Windows 10 IoT LTSC

- 정품 키 인증: [scripts/activate-win10-iot.cmd](scripts/activate-win10-iot.cmd) (펌웨어 OEM 키 자동 사용, 없으면 입력)
  - 다시 실행 시: 이미 정품 인증돼 있으면 건너뜀

- https://massgrave.dev/ 참고해서 인증 스크립트 실행
```powershell
irm https://get.activated.win | iex
```


### 컴퓨터 이름

- Setup: [scripts/setup-hostname.ps1](scripts/setup-hostname.ps1) (컴퓨터 이름이 `titan-s260`이 아니면 변경, 적용 후 재부팅)
  - 다시 실행 시: 이름이 이미 `titan-s260`이거나 변경 후 재부팅 대기 중이면 건너뜀


### PowerToys

- Setup: [windows/scripts/setup-powertoys.ps1](../windows/scripts/setup-powertoys.ps1) (최신 버전)
  - 다시 실행 시: 설치돼 있고 창 억제·ZoomIt 설정이 돼 있으면 건너뜀. 설치만 돼 있으면 설정만 적용
  - 설치 후 환영 창, 새로운 기능(What's new) 창을 띄우지 않음
  - ZoomIt 활성화 (정책으로 켜서 PowerToys 설정에서 끌 수 없음)


<!-- 
### ZoomIt

- Setup: [windows/scripts/setup-zoomit.ps1](../windows/scripts/setup-zoomit.ps1)
 -->


### WinGet

- Setup: [windows/scripts/setup-winget.ps1](../windows/scripts/setup-winget.ps1) (winget이 없거나 실행되지 않을 때 설치, LTSC/IoT처럼 Microsoft Store가 없는 환경용)
  - winget GitHub 릴리스의 설치 파일, 의존 패키지, 라이선스 파일로 PC 전체에 등록 (`Add-AppxProvisionedPackage -LicensePath`) 후 현재 사용자에 바로 연결
  - 라이선스 없이 설치하면 "관련 앱 라이선스를 찾을 수 없습니다" 오류로 winget이 실행되지 않음
  - 다시 실행 시: `winget --version`이 실행되면 건너뜀


### Microsoft PC Manager

- Setup: [windows/scripts/setup-pcmanager.ps1](../windows/scripts/setup-pcmanager.ps1) (winget으로 Store 앱 설치, winget은 위 WinGet 단계에서 준비)
  - 다시 실행 시: winget 목록에 PC Manager가 있으면 건너뜀


### 저사양 최적화

- Setup: [scripts/setup-performance.ps1](scripts/setup-performance.ps1) (적용 후 재부팅)
  - 다시 실행 시: 시각 효과, 서비스, 원격 분석, 전원 계획, 최대 절전이 모두 적용돼 있으면 건너뜀
  1. 시각 효과 최적 성능 (투명·애니메이션 끄기, 단색 배경)
  2. Windows Search 인덱싱 끄기
  3. SysMain(Superfetch) 끄기
  4. 원격 분석(DiagTrack) 끄기
  5. 전원: 고성능, 화면 끄기·절전·USB 절전 해제
  6. 최대 절전 끄기 (hiberfil.sys 삭제)


### Windows 설정

- 작업표시줄 터치 키보드 버튼 켬: [scripts/setup-touch-keyboard.ps1](scripts/setup-touch-keyboard.ps1) (현재 사용자, 로그아웃 또는 재부팅 후 적용)
  - 다시 실행 시: 터치 키보드 버튼이 이미 켜져 있으면 건너뜀


