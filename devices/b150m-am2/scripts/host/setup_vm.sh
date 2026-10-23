#!/usr/bin/env bash
# OpenClaw용 Ubuntu Server 24.04 VM 생성 스크립트 (Proxmox 호스트에서 root로 실행)
# Proxmox 공식 Cloud-Init 방식: Ubuntu 공식 cloud 이미지를 디스크로 가져오고 cloud-init으로 계정, SSH 키, IP를 설정
# 첫 부팅 때 vendor-data(snippets)로 저장소를 클론해 VM 안의 setup.sh를 실행하므로, 사용자는 온보딩만 하면 됨
# 값은 devices/b150m-am2/.env에서 읽고, 없으면 기본값 사용 (.env.example 참고)
# 공식 문서: https://pve.proxmox.com/wiki/Cloud-Init_Support
# 사용법: bash scripts/host/setup_vm.sh
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
vm_name="${VM_NAME:-ubuntu-server}"
vm_cores="${VM_CORES:-2}"
vm_memory="${VM_MEMORY_MB:-2048}"
vm_disk="${VM_DISK_GB:-32}"
vm_storage="${VM_STORAGE:-local-lvm}"
vm_bridge="${VM_BRIDGE:-vmbr0}"
vm_user="${VM_USER:-ubuntu}"
ssh_keys_file="${VM_SSH_KEYS_FILE:-/root/.ssh/authorized_keys}"
auto_openclaw="${VM_AUTO_OPENCLAW:-yes}"

image_url=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
sums_url=https://cloud-images.ubuntu.com/noble/current/SHA256SUMS
# first boot 작업 파일은 기본 local 저장소(경로 /var/lib/vz)의 snippets에 둠
snippet_storage=local
snippet_dir=/var/lib/vz/snippets
snippet_name="b150m-am2-vm-${vm_id}.yaml"

# 같은 번호의 VM이 있으면 건너뜀 (기존 VM은 건드리지 않음)
if qm status "$vm_id" >/dev/null 2>&1; then
    existing="$(qm config "$vm_id" | awk -F': ' '$1 == "name" { print $2 }')"
    if [[ "$existing" != "$vm_name" ]]; then
        echo "VM $vm_id already exists with another name ($existing). Set VM_ID in $env_file." >&2
        exit 1
    fi
    skip_done "VM $vm_id ($vm_name) already exists"
fi

# 설정값 확인
for n in "$vm_id" "$vm_cores" "$vm_memory" "$vm_disk"; do
    [[ "$n" =~ ^[0-9]+$ ]] || { echo "Invalid number in VM settings: $n" >&2; exit 1; }
done
pvesm status --storage "$vm_storage" >/dev/null 2>&1 || { echo "Storage not found: $vm_storage" >&2; exit 1; }
ip link show "$vm_bridge" >/dev/null 2>&1 || { echo "Bridge not found: $vm_bridge" >&2; exit 1; }
if [[ ! -s "$ssh_keys_file" ]]; then
    echo "SSH public key file is empty or missing: $ssh_keys_file (set VM_SSH_KEYS_FILE in $env_file)" >&2
    exit 1
fi
if [[ -n "${VM_IP:-}" ]]; then
    [[ "$VM_IP" =~ ^[0-9.]+/[0-9]+$ ]] || { echo "VM_IP must be CIDR (e.g. 10.10.10.2/24): $VM_IP" >&2; exit 1; }
    ipconfig="ip=$VM_IP${VM_GATEWAY:+,gw=$VM_GATEWAY}"
else
    ipconfig="ip=dhcp"
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 1. Ubuntu 공식 cloud 이미지 다운로드와 체크섬 확인
echo "[1/5] Downloading the Ubuntu 24.04 cloud image"
curl -fL --retry 3 -o "$work/image.img" "$image_url"
expected="$(curl -fsSL "$sums_url" | awk '$2 == "*noble-server-cloudimg-amd64.img" { print $1 }')"
actual="$(sha256sum "$work/image.img" | awk '{ print $1 }')"
if [[ -z "$expected" || "$expected" != "$actual" ]]; then
    echo "Checksum mismatch for the cloud image (expected ${expected:-none}, got $actual)" >&2
    exit 1
fi
echo "Checksum OK"

# 2. VM 생성, 이미지를 디스크로 가져와 크기 조정
echo "[2/5] Creating VM $vm_id ($vm_name)"
qm create "$vm_id" --name "$vm_name" --ostype l26 --cpu host \
    --cores "$vm_cores" --memory "$vm_memory" \
    --net0 "virtio,bridge=$vm_bridge" --scsihw virtio-scsi-pci --agent enabled=1
qm set "$vm_id" --scsi0 "$vm_storage:0,import-from=$work/image.img"
qm resize "$vm_id" scsi0 "${vm_disk}G"
qm set "$vm_id" --ide2 "$vm_storage:cloudinit" --boot order=scsi0 --serial0 socket --vga serial0

# 3. cloud-init: 계정, SSH 키, IP
echo "[3/5] Configuring cloud-init ($vm_user, $ipconfig)"
qm set "$vm_id" --ciuser "$vm_user" --sshkeys "$ssh_keys_file" --ipconfig0 "$ipconfig"
if [[ -n "${VM_DNS:-}" ]]; then
    qm set "$vm_id" --nameserver "$VM_DNS"
fi

# 4. 첫 부팅 작업: guest agent 설치, 저장소 클론 후 VM의 setup.sh 실행 (OpenClaw 설치)
#    cloud 이미지의 기본 사용자는 비밀번호 없이 sudo가 되므로, 사용자로 sudo를 실행해 SUDO_USER가 그 사용자가 되게 함
echo "[4/5] Writing first boot tasks"
if [[ "$auto_openclaw" == yes ]]; then
    # snippets를 둘 수 있게 local 저장소의 content에 snippets 추가
    content="$(awk '/^[a-z]+: /{ s = ($2 == "'"$snippet_storage"'") } s && $1 == "content" { print $2 }' /etc/pve/storage.cfg)"
    if [[ ",$content," != *,snippets,* ]]; then
        pvesm set "$snippet_storage" --content "${content:+$content,}snippets"
    fi
    mkdir -p "$snippet_dir"
    cat > "$snippet_dir/$snippet_name" <<EOF
#cloud-config
package_update: true
packages:
  - qemu-guest-agent
  - git
runcmd:
  - systemctl enable --now qemu-guest-agent
  - sudo -u $vm_user -H git clone https://github.com/s1len7/silent_sdk.git /home/$vm_user/silent_sdk
  - sudo -u $vm_user -H sudo bash /home/$vm_user/silent_sdk/devices/b150m-am2/setup.sh
EOF
    qm set "$vm_id" --cicustom "vendor=$snippet_storage:snippets/$snippet_name"
else
    echo "VM_AUTO_OPENCLAW=$auto_openclaw, first boot tasks skipped"
fi

# 5. 시작 (부팅 시 자동 시작도 켬)
echo "[5/5] Starting VM $vm_id"
qm set "$vm_id" --onboot 1
qm start "$vm_id"

echo "VM $vm_id ($vm_name) started. First boot takes several minutes."
echo "Console: qm terminal $vm_id (exit with Ctrl+O). After first boot, log in as $vm_user and run: openclaw onboard --install-daemon"
