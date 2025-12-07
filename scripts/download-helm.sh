#!/bin/bash
# Download and install the latest version of Helm

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi

echo "Downloading Helm for ${ARCH}..."

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download latest version using official script
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 > get_helm.sh
chmod +x get_helm.sh
./get_helm.sh --no-sudo

# Move to local bin directory
mkdir -p $OLDPWD/bin
mv /usr/local/bin/helm $OLDPWD/bin/ 2>/dev/null || true

# If helm is still in /usr/local/bin, try with sudo or copy it
if [ -f /usr/local/bin/helm ]; then
    cp /usr/local/bin/helm $OLDPWD/bin/
fi

# Clean up
cd "$OLDPWD"
rm -rf "$TMP_DIR"

echo "Helm installed successfully in $PWD/bin"
