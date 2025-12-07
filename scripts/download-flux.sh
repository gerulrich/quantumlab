#!/bin/bash
# Download and install the latest version of Flux CLI

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi

echo "Downloading Flux CLI for ${ARCH}..."

# Download latest version
curl -s https://fluxcd.io/install.sh | bash -s $PWD/bin

echo "Flux CLI installed successfully in $PWD/bin"
