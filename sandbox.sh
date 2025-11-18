\#!/usr/bin/env bash
set -euo pipefail

ISO_NAME="ubuntu-24.04.3-desktop-amd64.iso"
ISO_URL="https://releases.ubuntu.com/24.04/${ISO_NAME}"
SHA256_URL="https://releases.ubuntu.com/24.04/SHA256SUMS"
DOWNLOADS="$HOME/Downloads/${ISO_NAME}"
CACHE="$HOME/.cache/sandbox/${ISO_NAME}"
CACHE_SUM="$HOME/.cache/sandbox/SHA256SUMS"

# --- Dependency check (no auto-install - handled by apt) ---
need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: Required dependency '$1' not found."
    echo "Please install it with: sudo apt install $2"
    exit 1
  fi
}

need_cmd qemu-system-x86_64 "qemu-system-x86 qemu-utils"
need_cmd curl "curl"
need_cmd sha256sum "coreutils"

# --- Download helper with resume + retries ---
download_iso() {
  local target="$1"
  echo "Downloading ISO (resume enabled)..."
  for i in {1..5}; do
    if curl --continue-at - --fail -L -o "$target" "$ISO_URL"; then
      return 0
    else
      echo "Download attempt $i failed, retrying in $((i*10))s..."
      sleep $((i*10))
    fi
  done
  echo "Error: ISO download failed after retries."
  exit 1
}

# --- Find ISO ---
ISO=""
if [ -f "$DOWNLOADS" ]; then
  ISO="$DOWNLOADS"
  echo "Using ISO from Downloads: $ISO"
elif [ -f "$CACHE" ]; then
  ISO="$CACHE"
  echo "Using cached ISO: $ISO"
else
  echo "No ISO found, downloading fresh..."
  mkdir -p "$(dirname "$CACHE")"
  download_iso "$CACHE"
  ISO="$CACHE"
fi

# --- Sanity check (~2GB minimum) ---
if [ ! -s "$ISO" ] || [ "$(stat -c%s "$ISO" 2>/dev/null || stat -f%z "$ISO")" -lt 2000000000 ]; then
  echo "Cached ISO looks invalid (too small). Re-downloading..."
  rm -f "$ISO"
  download_iso "$CACHE"
  ISO="$CACHE"
fi

# --- Checksum verification ---
echo "Fetching official SHA256SUMS..."
curl -L -o "$CACHE_SUM" "$SHA256_URL"

EXPECTED_SUM=$(grep "$ISO_NAME" "$CACHE_SUM" | awk '{print $1}')
ACTUAL_SUM=$(sha256sum "$ISO" | awk '{print $1}')

if [ "$EXPECTED_SUM" != "$ACTUAL_SUM" ]; then
  echo "Checksum mismatch! Re-downloading ISO..."
  rm -f "$ISO"
  download_iso "$CACHE"
  ISO="$CACHE"
  ACTUAL_SUM=$(sha256sum "$ISO" | awk '{print $1}')
  if [ "$EXPECTED_SUM" != "$ACTUAL_SUM" ]; then
    echo "Error: ISO checksum still invalid after re-download."
    exit 1
  fi
fi

echo "✅ ISO verified successfully against official SHA256SUMS."

# --- Resource detection ---
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
MEM=$((TOTAL_MEM / 2))
[ "$MEM" -gt 8192 ] && MEM=8192
[ "$MEM" -lt 2048 ] && MEM=2048

CPUS="$(nproc --all 2>/dev/null || echo 2)"
[ "$CPUS" -gt 4 ] && CPUS=4
[ "$CPUS" -lt 1 ] && CPUS=1

# --- Create temporary disk (optional installation target) ---
DISK_IMG="/tmp/sandbox-disk-$$.qcow2"
echo "Creating temporary 32GB disk image..."
qemu-img create -f qcow2 "$DISK_IMG" 32G >/dev/null
trap "rm -f '$DISK_IMG'" EXIT

# --- KVM acceleration if available ---
ACCEL_ARGS=()
if [ -e /dev/kvm ]; then
  ACCEL_ARGS=(-enable-kvm -cpu host)
  echo "✅ KVM acceleration enabled"
else
  echo "⚠️  Note: /dev/kvm not found. Running without hardware acceleration (slower)."
fi

echo ""
echo "🚀 Launching disposable Ubuntu Desktop..."
echo "   Memory: ${MEM}MB | CPUs: ${CPUS} | Disk: ${DISK_IMG}"
echo ""

exec qemu-system-x86_64 \
  -m "$MEM" \
  -smp "$CPUS" \
  -cdrom "$ISO" \
  -drive file="$DISK_IMG",format=qcow2,if=virtio \
  -boot d \
  -net nic,model=virtio -net user \
  -vga virtio \
  -display gtk,grab-on-hover=on \
  -usb -device usb-tablet \
  "${ACCEL_ARGS[@]+"${ACCEL_ARGS[@]}"}"
