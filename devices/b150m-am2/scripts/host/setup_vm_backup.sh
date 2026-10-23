#!/usr/bin/env bash
# VM 정기 백업 설정 스크립트 (Proxmox 호스트에서 root로 실행, setup_vm_ubuntu_server.sh 다음에 실행)
# OpenClaw 에이전트가 VM 안을 망가뜨려도 되돌릴 수 있도록 Proxmox 백업 job(vzdump)을 등록함
# 스냅샷 모드라 VM을 끄지 않고 백업하고, 오래된 백업은 개수 기준으로 자동 삭제함
# 값은 devices/b150m-am2/.env에서 읽고, 없으면 기본값 사용 (.env.example 참고)
# 공식 문서: https://pve.proxmox.com/wiki/Backup_and_Restore
# 사용법: bash scripts/host/setup_vm_backup.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run as root: bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/../lib.sh"

if ! command -v pveversion >/dev/null; then
    echo "Not a Proxmox host. Run this script on the Proxmox host." >&2
    exit 1
fi

device_dir="$(cd "$(dirname "$0")/../.." && pwd)"
env_file="$device_dir/.env"
if [[ -f "$env_file" ]]; then
    # Windows에서 편집해 CR이 들어갔으면 제거
    sed -i 's/\r$//' "$env_file"
    # shellcheck source=/dev/null
    source "$env_file"
fi

vm_id="${VM_ID:-100}"
schedule="${VM_BACKUP_SCHEDULE:-sun 03:00}"
keep="${VM_BACKUP_KEEP:-3}"
# 백업 파일은 기본 local 저장소(경로 /var/lib/vz/dump)에 둠
storage=local
job_id="b150m-am2-vm-$vm_id"

# 같은 job이 있으면 건너뜀 (웹 UI에서 바꾼 일정·보관 개수는 그대로 둠)
if pvesh get "/cluster/backup/$job_id" >/dev/null 2>&1; then
    skip_done "Backup job $job_id already exists"
fi

# 설정값 확인
[[ "$keep" =~ ^[1-9][0-9]*$ ]] || { echo "VM_BACKUP_KEEP must be a positive number: $keep" >&2; exit 1; }
qm status "$vm_id" >/dev/null 2>&1 || { echo "VM $vm_id not found. Create the VM first." >&2; exit 1; }
pvesm status --storage "$storage" --content backup >/dev/null 2>&1 \
    || { echo "Storage $storage does not allow backups." >&2; exit 1; }

echo "Creating backup job $job_id (VM $vm_id, '$schedule', keep last $keep, storage $storage)"
pvesh create /cluster/backup --id "$job_id" --vmid "$vm_id" --schedule "$schedule" \
    --storage "$storage" --mode snapshot --compress zstd --prune-backups "keep-last=$keep" \
    --comment "silent_sdk: weekly backup of VM $vm_id"

echo "Backup job created. Run now from the web UI (Datacenter > Backup > Run now) or: vzdump $vm_id --storage $storage --mode snapshot --compress zstd"
