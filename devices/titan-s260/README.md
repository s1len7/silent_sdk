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
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/titan-s260/setup.ps1 | iex
```

- 저장소: 실행할 때마다 `C:\silent_sdk`에 최신 버전을 받음 (git clone이면 `git pull`, 아니면 zip으로 새로 받아 폴더를 교체하고 `logs`와 `.env`는 유지)
- 실패한 단계가 있어도 나머지 단계는 계속 진행하고, 끝에 단계별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 단계는 SKIP하고, 실패했거나 안 된 단계만 다시 진행함 (단계별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `C:\silent_sdk\logs\titan-s260-<시각>\` (`setup.log` 전체 실행 기록, `*-install.log` 설치 프로그램 로그)


### Windows 10 IoT LTSC

- 제품키 인증: [scripts/activate-win10-iot.cmd](scripts/activate-win10-iot.cmd) (펌웨어 OEM 키 자동 사용, 없으면 입력)
  - 다시 실행 시: 이미 정품 인증돼 있으면 건너뜀

혹은

- https://massgrave.dev/ 참고해서 인증 스크립트 실행
```powershell
irm https://get.activated.win | iex
```


### hostname 설정

- Setup: [desktop/scripts/setup-hostname.ps1](../desktop/scripts/setup-hostname.ps1) (desktop 공통 스크립트, 새 hostname을 물어봄, 엔터를 누르면 기본값 `titan-s260`, 적용 후 재부팅)
  - 다시 실행 시: 고른 hostname이 지금 hostname과 같거나, 변경 후 재부팅 대기 중이면 건너뜀


### Windows 업데이트

- Setup: [desktop/scripts/setup-windows-update.ps1](../desktop/scripts/setup-windows-update.ps1) (드라이버 포함 모든 업데이트 설치, Windows 내장 업데이트 API 사용)
  - 기능 업데이트(Windows 버전 변경)와 사용자 입력이 필요한 업데이트는 제외
  - 업데이트를 하나씩 받고 설치하며 진행 막대와 `[3/25]` 같은 진행 줄을 보여줌
  - 업데이트 하나가 오래 걸려도 1분마다 `still working ... (경과 시간)` 줄을 남겨 멈추지 않았음을 알 수 있음 (로그에도 기록)
  - 자동으로 재부팅하지 않음. 재부팅이 필요하면 재부팅 후 전체 Setup을 다시 실행해 남은 업데이트 설치
  - 다시 실행 시: 설치할 업데이트가 없거나, 이전 업데이트의 재부팅이 대기 중이면 건너뜀


### PowerToys

- Setup: [desktop/scripts/setup-powertoys.ps1](../desktop/scripts/setup-powertoys.ps1) (최신 버전)
  - 다시 실행 시: 설치돼 있고 창 억제·ZoomIt 설정이 돼 있으면 건너뜀. 설치만 돼 있으면 설정만 적용
  - 설치 후 환영 창, 새로운 기능(What's new) 창을 띄우지 않음
  - ZoomIt 활성화 (정책으로 켜서 PowerToys 설정에서 끌 수 없음)


<!-- 
### ZoomIt

- Setup: [desktop/scripts/setup-zoomit.ps1](../desktop/scripts/setup-zoomit.ps1)
 -->


### WinGet

- Setup: [desktop/scripts/setup-winget.ps1](../desktop/scripts/setup-winget.ps1) (winget이 없거나 실행되지 않을 때 설치, LTSC/IoT처럼 Microsoft Store가 없는 환경용)
  - winget GitHub 릴리스의 설치 파일, 의존 패키지, 라이선스 파일로 PC 전체에 등록 (`Add-AppxProvisionedPackage -LicensePath`) 후 현재 사용자에 바로 연결
  - 라이선스 없이 설치하면 "관련 앱 라이선스를 찾을 수 없습니다" 오류로 winget이 실행되지 않음
  - 다시 실행 시: `winget --version`이 실행되면 건너뜀


### Microsoft PC Manager

- Setup: [desktop/scripts/setup-pcmanager.ps1](../desktop/scripts/setup-pcmanager.ps1) (winget으로 Store 앱 설치, winget은 위 WinGet 단계에서 준비)
  - 다시 실행 시: winget 목록에 PC Manager가 있으면 건너뜀


### Sysinternals Suite

- Setup: [desktop/scripts/setup-sysinternals.ps1](../desktop/scripts/setup-sysinternals.ps1) (Program Files 설치, PATH 추가, EULA 자동 동의)
  - 다시 실행 시: 설치 폴더, PATH, EULA 동의가 모두 돼 있으면 건너뜀


### 자동 로그인

- Setup: [desktop/scripts/setup-autologon.ps1](../desktop/scripts/setup-autologon.ps1) (현재 로그인한 로컬 계정, Sysinternals Autologon 사용, 다음 부팅부터 적용)
  - 다시 실행 시: 자동 로그인이 현재 계정으로 켜져 있으면 건너뜀
  - 실행 중 계정 비밀번호를 물음. 비밀번호가 맞는지 확인한 뒤 설정하고, 빈 값으로 Enter를 누르면 건너뜀


### 저사양 최적화

- Setup: [scripts/setup-performance.ps1](scripts/setup-performance.ps1) (적용 후 재부팅)
  - 다시 실행 시: 시각 효과, 서비스, 원격 분석, 전원 계획, 최대 절전이 모두 적용돼 있으면 건너뜀
  1. 시각 효과 최적 성능 (투명·애니메이션 끄기, 단색 배경)
  2. Windows Search 인덱싱 끄기
  3. SysMain(Superfetch) 끄기
  4. 원격 분석(DiagTrack) 끄기
  5. 전원: 고성능, 화면 끄기·절전·USB 절전 해제
  6. 최대 절전 끄기 (hiberfil.sys 삭제)


### 바탕화면 아이콘

- Setup: [desktop/scripts/setup-desktop-icons.ps1](../desktop/scripts/setup-desktop-icons.ps1) (내 PC, 사용자 폴더, 네트워크, 제어판, 휴지통 아이콘 표시, 현재 사용자)
  - 설정 > 개인 설정 > 테마 > 바탕 화면 아이콘 설정과 같은 값
  - 바탕화면에서 F5(새로 고침)하거나 다시 로그인하면 보임
  - 다시 실행 시: 다섯 아이콘이 모두 표시로 설정돼 있으면 건너뜀


### Windows 설정

- 작업표시줄 터치 키보드 버튼 켬: [scripts/setup-touch-keyboard.ps1](scripts/setup-touch-keyboard.ps1) (현재 사용자, 로그아웃 또는 재부팅 후 적용)
  - 다시 실행 시: 터치 키보드 버튼이 이미 켜져 있으면 건너뜀


