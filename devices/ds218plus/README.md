# Synology DS218+

- 제조사: [시놀로지(Synology)](https://www.synology.com/)
- 모델명: DiskStation DS218+
  - [데이터시트](https://global.download.synology.com/download/Document/Hardware/DataSheet/DiskStation/18-year/DS218+/enu/Synology_DS218_Plus_Data_Sheet_enu.pdf)
- 지원OS: DSM 7

| 항목 | 사양 |
| --- | --- |
| CPU | Intel Celeron J3355 (2코어, 2.0GHz / 최대 2.5GHz), AES-NI |
| RAM | 12GB DDR3L (기본 2GB에서 업그레이드, 공식 지원 최대 6GB) |
| 저장장치 | 3.5"/2.5" SATA HDD·SSD 2베이 |
| 하드웨어 트랜스코딩 | H.264, H.265, MPEG-2, VC-1 (최대 4K) |
| 포트 | USB 3.0 x3, eSATA x1 |
| LAN | 기가비트(RJ-45) x1 |


## 기능

- 재설치 자동화 대신 Container Manager(Docker) 프로젝트의 생성·수정·업데이트를 관리함 (전체 Setup 없음)
- 프로젝트는 `projects/<프로젝트>/`에 두고, NAS의 `/volume1/docker/<프로젝트>`에 배포함
- 제어: 저장소를 받은 PC에서 ssh(키 인증)로 NAS(`192.168.0.2`)에 접속해 실행
