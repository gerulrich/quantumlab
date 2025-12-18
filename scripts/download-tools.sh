#!/bin/bash

mkdir -p $PWD/bin
CLI_ARCH=amd64
if [ "$(uname -m)" = "arm64"  ] || [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
OS=$(uname | tr '[:upper:]' '[:lower:]')


CILIUM_CLI_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | jq -r .tag_name)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${OS}-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-${OS}-${CLI_ARCH}.tar.gz.sha256sum
tar xzvfC cilium-${OS}-${CLI_ARCH}.tar.gz $PWD/bin
rm cilium-${OS}-${CLI_ARCH}.tar.gz{,.sha256sum}
chmod +x $PWD/bin/cilium


FLUXCD_CLI_VERSION=$(curl -s https://api.github.com/repos/fluxcd/flux2/releases/latest | jq -r .tag_name)
curl -L --fail --remote-name-all https://github.com/fluxcd/flux2/releases/download/${FLUXCD_CLI_VERSION}/flux_${FLUXCD_CLI_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
tar xzvfC flux_${FLUXCD_CLI_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz $PWD/bin
rm flux_${FLUXCD_CLI_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
chmod +x $PWD/bin/flux

HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name)
curl -L --fail --remote-name-all https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${CLI_ARCH}.tar.gz
tar xzvfC helm-${HELM_VERSION}-${OS}-${CLI_ARCH}.tar.gz $PWD/bin
rm helm-${HELM_VERSION}-${OS}-${CLI_ARCH}.tar.gz
mv $PWD/bin/${OS}-${CLI_ARCH}/helm $PWD/bin/helm
rm -rf $PWD/bin/${OS}-${CLI_ARCH}
chmod +x $PWD/bin/helm


KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${CLI_ARCH}/kubectl"
chmod +x kubectl
mv kubectl $PWD/bin/