#!/bin/bash
# Download and install the latest version of kubectl

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi

echo "Downloading kubectl for ${ARCH}..."

# Download latest stable version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"

# Install to local bin directory
chmod +x kubectl
mkdir -p $PWD/bin
mv kubectl $PWD/bin/

echo "kubectl installed successfully in $PWD/bin"
