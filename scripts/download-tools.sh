#!/bin/bash

set -e

mkdir -p $PWD/bin
CLI_ARCH=amd64
if [ "$(uname -m)" = "arm64"  ] || [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
OS=$(uname | tr '[:upper:]' '[:lower:]')

# Función para descargar y versionar binarios
download_versioned_binary() {
    local tool_name=$1
    local version=$2
    local download_cmd=$3
    local versioned_binary="$PWD/bin/${tool_name}-${version}"
    local symlink="$PWD/bin/${tool_name}"
    
    # Verificar si la versión ya existe
    if [ -f "$versioned_binary" ]; then
        echo "✓ ${tool_name} ${version} ya existe"
    else
        echo "⬇ Descargando ${tool_name} ${version}..."
        cd $PWD/bin
        eval "$download_cmd"
        cd - > /dev/null
        chmod +x "$versioned_binary"
    fi
    
    # Actualizar o crear symlink
    if [ -L "$symlink" ]; then
        rm "$symlink"
    fi
    ln -s "${tool_name}-${version}" "$symlink"
    echo "✓ ${tool_name} -> ${tool_name}-${version}"
}

# Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | jq -r .tag_name)
download_versioned_binary "cilium" "$CILIUM_CLI_VERSION" "
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${OS}-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-${OS}-${CLI_ARCH}.tar.gz.sha256sum
    tar xzf cilium-${OS}-${CLI_ARCH}.tar.gz
    mv cilium cilium-${CILIUM_CLI_VERSION}
    rm cilium-${OS}-${CLI_ARCH}.tar.gz{,.sha256sum}
"

# Flux CLI
FLUXCD_CLI_VERSION=$(curl -s https://api.github.com/repos/fluxcd/flux2/releases/latest | jq -r .tag_name)
download_versioned_binary "flux" "$FLUXCD_CLI_VERSION" "
    curl -L --fail --remote-name-all https://github.com/fluxcd/flux2/releases/download/${FLUXCD_CLI_VERSION}/flux_${FLUXCD_CLI_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
    tar xzf flux_${FLUXCD_CLI_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
    mv flux flux-${FLUXCD_CLI_VERSION}
    rm flux_${FLUXCD_CLI_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
"

# Helm
HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name)
download_versioned_binary "helm" "$HELM_VERSION" "
    curl -L --fail --remote-name-all https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${CLI_ARCH}.tar.gz
    tar xzf helm-${HELM_VERSION}-${OS}-${CLI_ARCH}.tar.gz
    mv ${OS}-${CLI_ARCH}/helm helm-${HELM_VERSION}
    rm -rf helm-${HELM_VERSION}-${OS}-${CLI_ARCH}.tar.gz ${OS}-${CLI_ARCH}
"

# kubectl
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
download_versioned_binary "kubectl" "$KUBECTL_VERSION" "
    curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${CLI_ARCH}/kubectl
    mv kubectl kubectl-${KUBECTL_VERSION}
"

# k9s
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
download_versioned_binary "k9s" "$K9S_VERSION" "
    curl -L --fail --remote-name-all https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_${OS}_${CLI_ARCH}.tar.gz
    tar xzf k9s_${OS}_${CLI_ARCH}.tar.gz
    mv k9s k9s-${K9S_VERSION}
    rm k9s_${OS}_${CLI_ARCH}.tar.gz
"

# talosctl
TALOSCTL_VERSION=$(curl -s https://api.github.com/repos/siderolabs/talos/releases/latest | jq -r .tag_name)
download_versioned_binary "talosctl" "$TALOSCTL_VERSION" "
    curl -L --fail -o talosctl-${TALOSCTL_VERSION} https://github.com/siderolabs/talos/releases/download/${TALOSCTL_VERSION}/talosctl-${OS}-${CLI_ARCH}
"

# Limpiar archivos innecesarios
rm -f $PWD/bin/LICENSE $PWD/bin/README.md

echo ""
echo "✓ Todas las herramientas han sido instaladas correctamente"