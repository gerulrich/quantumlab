#!/bin/bash

set -e

# Script to create virtual machines with QEMU/KVM using cloud-init
# Source: https://gist.github.com/alainpham/bb1ca9e6be54eb3bf633fa2098f68c9e

usage() {
  echo "usage: $0 -i|--image <image_path> -t|--target-dir <target_dir> [OPTIONS]"
  echo ""
  echo "This script creates a virtual machine with virt-install and QEMU/KVM"
  echo ""
  echo "REQUIRED PARAMETERS:"
  echo "   -i|--image         full path to the base image (e.g.: /path/to/image.qcow2)"
  echo "   -t|--target-dir    directory where the VM will be stored"
  echo ""
  echo "OPTIONS:"
  echo "   -n|--name          VM name (default: vm-\$(date +%s))"
  echo "   -c|--cpu           number of CPUs (default: 2)"
  echo "   -m|--memory        memory in MB (default: 2048)"
  echo "   -d|--disk          disk size in GB (default: 20)"
  echo "   --net              network type (default, macvtap, bridge) (default: default)"
  echo "   --bridge           bridge name when --net=bridge"
  echo "   -s|--static-ip     static IP address (format: IP/CIDR)"
  echo "   --gateway          gateway for static IP (default: auto-detected)"
  echo "   --dns              DNS servers separated by comma (default: 8.8.8.8,8.8.4.4)"
  echo "   --ssh-key          path to SSH public key (optional, not required for Talos)"
  echo "   --mac              MAC address for network interface (format: 52:54:00:XX:XX:XX)"
  echo "   --os-variant       OS variant for virt-install (default: ubuntu20.04)"
  echo "   --cloud-init       include custom cloud-init configuration"
  echo "   -h|--help          show this message"
  echo ""
  echo "EXAMPLES:"
  echo "  # Basic Ubuntu VM"
  echo "  $0 -i /path/to/ubuntu.qcow2 -t /var/lib/libvirt/images/myvm"
  echo ""
  echo "  # Talos VM (without SSH key)"
  echo "  $0 -i /path/to/talos.qcow2 -t /vms/talos01 -n talos01 -c 4 -m 4096"
  echo ""
  echo "  # VM with static IP and custom MAC"
  echo "  $0 -i /path/to/image.qcow2 -t /vms/server01 --static-ip 192.168.1.100/24 --mac 52:54:00:ab:cd:ef"
}

# Required variables
BASE_IMAGE=
TARGET_DIR=

# Optional variables with default values
VM_NAME="vm-$(date +%s)"
VM_CPU=2
VM_MEM=2048
VM_DISK=20
VM_NET="network=default"
VM_BRIDGE=
VM_STATIC_IP=
VM_GATEWAY=
VM_DNS="8.8.8.8,8.8.4.4"
SSH_KEY_PATH=
MAC_ADDRESS=
OS_VARIANT="ubuntu20.04"
USE_CLOUD_INIT=false

# Argument parsing
while [ $# -gt 0 ]; do
  case "$1" in
    -i | --image)
      BASE_IMAGE="$2"
      shift 2
      ;;
    -t | --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -n | --name)
      VM_NAME="$2"
      shift 2
      ;;
    -c | --cpu)
      VM_CPU="$2"
      shift 2
      ;;
    -m | --memory)
      VM_MEM="$2"
      shift 2
      ;;
    -d | --disk)
      VM_DISK="$2"
      shift 2
      ;;
    --net)
      case "$2" in
        default)
          VM_NET="network=default"
          ;;
        macvtap)
          VM_NET="type=direct,source=macvtap-net,model=virtio"
          ;;
        bridge)
          VM_NET="bridge"  # Will be completed with --bridge
          ;;
        *)
          echo "Error: Tipo de red inválido: $2 (use: default, macvtap, bridge)"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --bridge)
      VM_BRIDGE="$2"
      shift 2
      ;;
    -s | --static-ip)
      VM_STATIC_IP="$2"
      shift 2
      ;;
    --gateway)
      VM_GATEWAY="$2"
      shift 2
      ;;
    --dns)
      VM_DNS="$2"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY_PATH="$2"
      shift 2
      ;;
    --mac)
      MAC_ADDRESS="$2"
      shift 2
      ;;
    --os-variant)
      OS_VARIANT="$2"
      shift 2
      ;;
    --cloud-init)
      USE_CLOUD_INIT=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Parámetro inválido: $1"
      usage
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$BASE_IMAGE" ]; then
  echo "Error: You must specify the base image with -i|--image"
  usage
  exit 1
fi

if [ -z "$TARGET_DIR" ]; then
  echo "Error: You must specify the target directory with -t|--target-dir"
  usage
  exit 1
fi

# Validate that the base image exists
if [ ! -f "$BASE_IMAGE" ]; then
  echo "Error: Base image does not exist: $BASE_IMAGE"
  exit 1
fi

# Validate SSH key if provided
if [ -n "$SSH_KEY_PATH" ] && [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Error: SSH key does not exist: $SSH_KEY_PATH"
  exit 1
fi

# Validate MAC address format if provided
if [ -n "$MAC_ADDRESS" ]; then
  if ! echo "$MAC_ADDRESS" | grep -qE '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'; then
    echo "Error: Invalid MAC address format: $MAC_ADDRESS"
    echo "Expected format: XX:XX:XX:XX:XX:XX"
    exit 1
  fi
fi

# Configure bridge if specified
if [ "$VM_NET" = "bridge" ]; then
  if [ -z "$VM_BRIDGE" ]; then
    echo "Error: You must specify the bridge name with --bridge when using --net=bridge"
    exit 1
  fi
  VM_NET="bridge=$VM_BRIDGE,model=virtio"
fi

# Validate static IP with network type
if [ -n "$VM_STATIC_IP" ] && [ "$VM_NET" = "network=default" ]; then
  echo "Warning: Static IP with 'default' network may not work correctly"
  echo "Consider using --net=macvtap or --net=bridge"
fi

# Auto-detect gateway if there's a static IP but no gateway
if [ -n "$VM_STATIC_IP" ] && [ -z "$VM_GATEWAY" ]; then
  # Extract network from static IP (e.g.: 192.168.1.100/24 -> 192.168.1.1)
  NETWORK=$(echo "$VM_STATIC_IP" | cut -d'/' -f1 | awk -F'.' '{print $1"."$2"."$3".1"}')
  VM_GATEWAY="$NETWORK"
  echo "Info: Gateway auto-detected: $VM_GATEWAY"
fi

# Check that the VM doesn't exist
found=$(virsh list --all 2>/dev/null | awk 'FNR > 2 {print $2}' | head -n -1 | grep -E "^$VM_NAME\$" | wc -l || echo 0)
if [ "$found" -gt 0 ]; then
  echo "Error: VM '$VM_NAME' already exists"
  exit 1
fi

# Create VM directory
echo "$(date -R) Creating VM '$VM_NAME' with $VM_MEM MB RAM, $VM_CPU vCPU(s) and ${VM_DISK}GB disk..."
VM_DIR="$TARGET_DIR/$VM_NAME"
mkdir -p "$VM_DIR"

# Define file paths
VM_DISK_PATH="$VM_DIR/$VM_NAME.qcow2"
CI_ISO="$VM_DIR/$VM_NAME-cidata.iso"
USER_DATA="$VM_DIR/user-data"
META_DATA="$VM_DIR/meta-data"
NETWORK_CONFIG="$VM_DIR/network-config"

# Generate cloud-init configuration
echo "$(date -R) Generating cloud-init configuration..."

# user-data
if [ "$USE_CLOUD_INIT" = true ] || [ -n "$SSH_KEY_PATH" ]; then
  # Read SSH key if provided
  SSH_PUB_KEY=""
  if [ -n "$SSH_KEY_PATH" ]; then
    SSH_PUB_KEY=$(cat "$SSH_KEY_PATH")
  fi

  cat > "$USER_DATA" << _EOF_
#cloud-config
hostname: $VM_NAME
fqdn: $VM_NAME.local
manage_etc_hosts: true
_EOF_

  # Add SSH key if exists
  if [ -n "$SSH_PUB_KEY" ]; then
    cat >> "$USER_DATA" << _EOF_
users:
  - name: cloud-user
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - $SSH_PUB_KEY
_EOF_
  fi

  # Add network configuration if there's a static IP
  if [ -n "$VM_STATIC_IP" ]; then
    cat >> "$USER_DATA" << _EOF_
write_files:
  - path: /etc/network/interfaces.d/50-cloud-init.cfg
    permissions: '0644'
    content: |
      # This file is generated by cloud-init
      auto eth0
      iface eth0 inet static
        address $VM_STATIC_IP
        gateway $VM_GATEWAY
_EOF_
  fi
else
  # Minimal configuration without cloud-init (for Talos or others)
  cat > "$USER_DATA" << _EOF_
#cloud-config
hostname: $VM_NAME
_EOF_
fi

# meta-data
cat > "$META_DATA" << _EOF_
instance-id: $VM_NAME
local-hostname: $VM_NAME
_EOF_

# network-config (if there's a static IP)
if [ -n "$VM_STATIC_IP" ]; then
  # Convert DNS from CSV format to YAML array
  DNS_ARRAY=$(echo "$VM_DNS" | sed 's/,/\n        - /g')
  
  cat > "$NETWORK_CONFIG" << _EOF_
version: 2
ethernets:
  eth0:
    dhcp4: false
    dhcp6: false
    addresses:
      - $VM_STATIC_IP
    gateway4: $VM_GATEWAY
    nameservers:
      addresses:
        - $DNS_ARRAY
_EOF_
fi

# Create cloud-init ISO
echo "$(date -R) Creating cloud-init ISO..."
if [ -n "$VM_STATIC_IP" ]; then
  genisoimage -input-charset utf-8 -output "$CI_ISO" -volid cidata -joliet -rock "$USER_DATA" "$META_DATA" "$NETWORK_CONFIG" >/dev/null 2>&1
else
  genisoimage -input-charset utf-8 -output "$CI_ISO" -volid cidata -joliet -rock "$USER_DATA" "$META_DATA" >/dev/null 2>&1
fi

# Create VM disk
echo "$(date -R) Creating VM disk (${VM_DISK}GB)..."
qemu-img create -f qcow2 -o backing_file="$BASE_IMAGE" "$VM_DISK_PATH" "${VM_DISK}G" >/dev/null 2>&1

# Prepare network options
NETWORK_OPTS="--network $VM_NET"
if [ -n "$MAC_ADDRESS" ]; then
  NETWORK_OPTS="$NETWORK_OPTS,mac=$MAC_ADDRESS"
fi

# Install the VM
echo "$(date -R) Installing the VM..."
virt-install --import --name "$VM_NAME" --connect qemu:///system \
    --virt-type kvm \
    --ram "$VM_MEM" \
    --vcpus="$VM_CPU" \
    --os-variant "$OS_VARIANT" \
    --sound none \
    --rng /dev/urandom \
    --disk path="$VM_DISK_PATH",format=qcow2,bus=virtio \
    --disk "$CI_ISO",device=cdrom \
    $NETWORK_OPTS \
    --graphics vnc,listen=0.0.0.0 \
    --noautoconsole \
    --wait 0 \
    --boot menu=on

echo "$(date -R) VM '$VM_NAME' created successfully!"
echo ""
echo "VM Details:"
echo "  Name:         $VM_NAME"
echo "  CPUs:         $VM_CPU"
echo "  Memory:       $VM_MEM MB"
echo "  Disk:         ${VM_DISK}GB"
echo "  Directory:    $VM_DIR"
if [ -n "$VM_STATIC_IP" ]; then
  echo "  IP:           $VM_STATIC_IP"
  echo "  Gateway:      $VM_GATEWAY"
fi
if [ -n "$MAC_ADDRESS" ]; then
  echo "  MAC:          $MAC_ADDRESS"
fi
echo ""
echo "Useful commands:"
echo "  View status:  virsh dominfo $VM_NAME"
echo "  Connect:      virsh console $VM_NAME"
echo "  Start:        virsh start $VM_NAME"
echo "  Stop:         virsh shutdown $VM_NAME"
echo "  Remove:       virsh undefine $VM_NAME --remove-all-storage"
echo ""