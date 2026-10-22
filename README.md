# titan-s260

제조사: 신흥정밀 https://www.sam4s.com/kor/products/KCA03-3
- 메뉴얼, 드라이버, 유틸리티 : https://www.sam4s.com/kor/support/download


## 기능


### 전체 Setup

PowerShell에서 실행 (`C:\titan-s260`에 받은 뒤 전체 Setup 진행):

```powershell
irm https://raw.githubusercontent.com/s1len7/titan-s260/main/install.ps1 | iex
```

- 이미 받은 경우: [scripts/setup.cmd](scripts/setup.cmd) 실행
- 단계 추가: [scripts/setup.ps1](scripts/setup.ps1)의 `$steps`에 스크립트 추가


### Windows 10 IoT LTSC

- 정품 키 인증: [scripts/activate-win10-iot.cmd](scripts/activate-win10-iot.cmd) (펌웨어 OEM 키 자동 사용, 없으면 입력)
- https://massgrave.dev/ 참고해서 인증 스크립트 실행


