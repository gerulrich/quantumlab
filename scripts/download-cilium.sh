#!/bin/bash
# Download and install the latest version of cilium-cli

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
mkdir -p $PWD/bin
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz $PWD/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}