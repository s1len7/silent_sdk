# NVIDIA Jetson Nano Developer Kit (B01)

- 제조사: [NVIDIA](https://www.nvidia.com/)
- 모델명: [Jetson Nano Developer Kit](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-nano/product-development/) P3450, B01 리비전 (부품 번호 945-13450-0000-100)
  - 구성: Jetson Nano 모듈(P3448-0000) + 캐리어 보드(P3449)
  - [Developer Kit User Guide (DA_09402_003)](https://developer.download.nvidia.com/embedded/L4T/r32-3-1_Release_v1.0/Jetson_Nano_Developer_Kit_User_Guide.pdf)
  - [Yahboom Jetson Nano 학습 자료](https://www.yahboom.net/study/jetson-nano) (Yahboom의 튜토리얼 모음)
  - 초기 A02 리비전(945-13450-0000-000)과는 모듈·캐리어 보드가 호환되지 않음
- 지원OS: JetPack 4.6.6 (Jetson Linux R32.7.6, Ubuntu 18.04, aarch64)
  - Jetson Nano가 지원하는 마지막 버전이며, JetPack 4와 Ubuntu 18.04는 지원이 끝남

| 항목 | 사양 |
| --- | --- |
| CPU | ARM Cortex-A57 4코어, 1.43GHz |
| GPU | NVIDIA Maxwell 128코어, 최대 921MHz |
| RAM | 4GB 64-bit LPDDR4 (25.6GB/s) |
| 저장장치 | microSD (모듈 아래 슬롯, 16GB 이상 UHS-1) |
| 비디오 | 인코딩 4K30, 디코딩 4K60 (H.265) |
| 카메라 | MIPI CSI-2 커넥터 x2 (B01) |
| 디스플레이 | HDMI, DisplayPort |
| USB | USB 3.0 Type-A x4 (내장 허브, 2개씩 1A 제한), Micro-USB 2.0 x1 |
| 네트워크 | 기가비트 이더넷, M.2 Key E 슬롯 (Wi-Fi 카드용) |
| 확장 | 40핀 헤더 (3.3V 신호), PWM 팬 헤더, 버튼 헤더, 시리얼 콘솔 헤더 |
| 전원 | Micro-USB 5V 2A, 또는 DC 잭 5V 4A (J48 점퍼 연결 시) |
| 소비 전력 | 5W / 10W 모드 |


## 기능

- 전체 Setup: JetPack 4.6.6 SD카드 이미지로 첫 부팅 설정을 마친 뒤 이 한 줄만 실행 ([setup.sh](setup.sh)) (git이 없으면 설치 → 저장소 클론 → 전체 설치):

```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/jetson-nano-b01/setup.sh
```

- 이미 클론되어 있으면: `sudo bash ~/silent_sdk/devices/jetson-nano-b01/setup.sh` (`setup.sh`의 `modules` 목록 순서대로 실행)
- 개별 기능만 설치: 이 폴더(`~/silent_sdk/devices/jetson-nano-b01`)에서 `sudo bash scripts/setup_<기능>.sh`
- 실패한 모듈이 있어도 나머지 모듈은 계속 진행하고, 끝에 모듈별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함 (모듈별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~/silent_sdk/logs/jetson-nano-b01-<시각>/setup.log`
- 설치가 끝나면 재부팅 (zram 끄기, jtop 그룹 적용)


### CUDA 경로

- Setup: [scripts/setup_cuda_path.sh](scripts/setup_cuda_path.sh)
  - 다시 실행 시: `~/.bashrc`에 PATH, LD_LIBRARY_PATH 두 줄이 모두 있으면 건너뜀 (없는 줄만 추가)
- JetPack에는 CUDA 10.2가 `/usr/local/cuda`에 설치돼 있지만 PATH에 없어서 `nvcc: command not found`가 남
- `~/.bashrc` 끝에 아래 두 줄을 추가함. 새 터미널에서 `nvcc --version`으로 확인
```bash
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```
- 참고: Jetson은 `nvidia-smi`를 지원하지 않음. GPU 상태는 `tegrastats`나 jtop으로 확인


### jtop

- Setup: [scripts/setup_jtop.sh](scripts/setup_jtop.sh) (적용하려면 다시 로그인 또는 재부팅)
  - 다시 실행 시: jetson-stats 4.3.2가 설치돼 있고 `jtop.service`가 실행 중이면 건너뜀
- CPU, GPU, 메모리, 온도, 전력을 보는 Jetson 전용 모니터 ([jetson-stats](https://github.com/rbonghi/jetson_stats)), 실행: `jtop`


### 스왑

- Setup: [scripts/setup_swap.sh](scripts/setup_swap.sh) (zram 끄기는 재부팅 후 적용)
  - 다시 실행 시: `/mnt/4GB.swap`이 있고 `/etc/fstab`에 등록돼 있으며 zram(nvzramconfig)이 꺼져 있으면 건너뜀
- [NVIDIA jetson-inference 가이드](https://github.com/dusty-nv/jetson-inference/blob/master/docs/pytorch-transfer-learning.md#mounting-swap)대로 zram을 끄고 4GB 스왑파일을 만들어 `/etc/fstab`에 등록함
- 확인: `free -h`, `swapon --show`


### 데스크탑 끄기 (수동)

- 자동 설치에는 넣지 않음. 모니터 없이 쓰거나 메모리가 부족할 때만 적용
- 데스크탑을 끄면 메모리가 약 800MB(Unity/GNOME 기준) 늘어남 ([NVIDIA jetson-inference 가이드](https://github.com/dusty-nv/jetson-inference/blob/master/docs/pytorch-transfer-learning.md#disabling-the-desktop-gui))
```bash
sudo systemctl set-default multi-user.target  # 부팅 시 데스크탑 끄기
sudo systemctl set-default graphical.target   # 다시 켜기
```
