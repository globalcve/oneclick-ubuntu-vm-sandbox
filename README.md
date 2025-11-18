# Ubuntu Sandbox VM - One-Click Launcher

🚀 Automatically downloads, verifies, and launches Ubuntu 24.04 Desktop in a disposable QEMU virtual machine with zero configuration.

## ✨ Features

- ✅ **Automatic ISO management** - Downloads and caches Ubuntu 24.04 Desktop ISO
- ✅ **Cryptographic verification** - SHA256 checksum validation against official Ubuntu sources
- ✅ **Hardware acceleration** - Automatic KVM detection and usage
- ✅ **Temporary disk** - 32GB qcow2 image auto-deleted on exit (no traces left)
- ✅ **Smart resource allocation** - Detects and allocates optimal CPU/RAM (50% of host, max 8GB)
- ✅ **Resume support** - Interrupted downloads can be resumed
- ✅ **Network ready** - VM has internet access via user-mode networking
- ✅ **True disposable** - Every launch is a fresh environment

## 🔒 Security Note

This provides good isolation for testing and experimentation, but is **not a maximum-security sandbox**. The VM has network access and shares the display server. Suitable for testing unknown software and preventing accidental host damage, but not recommended for analyzing malicious code.

## 📦 Installation

### Method 1: .deb Package (Recommended)
```bash
# Download the package
wget https://github.com/globalcve/oneclick-ubuntu-vm-sandbox/releases/download/1.00/sandbox-vm_1.0.deb

# Install it
sudo dpkg -i sandbox-vm_1.0.deb

# Fix dependencies if needed
sudo apt install -f
```

### Method 2: Direct Script
```bash
# Download the script
wget https://raw.githubusercontent.com/globalcve/oneclick-ubuntu-vm-sandbox/main/sandbox.sh

# Make it executable
chmod +x sandbox.sh

# Move to PATH (optional)
sudo mv sandbox.sh /usr/local/bin/sandbox
```

## 🚀 Usage

Simply run:
```bash
sandbox
```

On first run, it will:
1. Download Ubuntu 24.04 Desktop ISO (~6GB)
2. Verify cryptographic checksums
3. Cache the ISO for future use
4. Launch the VM

Subsequent runs use the cached ISO and launch instantly.

## 💻 System Requirements

- **OS**: Ubuntu/Debian-based Linux distribution
- **RAM**: 4GB+ recommended (VM uses 50% of host RAM, max 8GB)
- **Disk**: 6GB free space for ISO cache
- **CPU**: Multi-core recommended (VM uses up to 4 cores)
- **Optional**: `/dev/kvm` for hardware acceleration (10x faster)

## 📦 Dependencies

The following packages are required (auto-installed with .deb):
- `qemu-system-x86` - QEMU x86 system emulator
- `qemu-utils` - QEMU disk image utilities
- `curl` - Download tool
- `coreutils` - SHA256 checksums

## 🎯 Use Cases


**Made with ❤️ by JEGLY for safe experimentation**
