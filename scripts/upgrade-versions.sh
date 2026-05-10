#!/bin/bash

# Configuration files
ENV_FILE="scripts/quantum-env.sh"
README_FILE="README.md"
API_GATEWAY_DOC="docs/setup/cilium-api-gateway.md"
TAILSCALE_RELEASE_FILE="helm/tailscale-operator/release.yaml"

# Helper function to confirm changes
confirm() {
    local prompt="$1"
    local response
    read -p "$prompt (y/n): " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Get latest Talos version
TALOS_VERSION=$(curl -s https://api.github.com/repos/siderolabs/talos/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "Talos version: $TALOS_VERSION"
sed -i.bak "s/export TALOS_VERSION=\".*\"/export TALOS_VERSION=\"$TALOS_VERSION\"/" "$ENV_FILE"
rm -f "$ENV_FILE.bak"

# Get latest Kubernetes version
KUBERNETES_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "Kubernetes version: $KUBERNETES_VERSION"
sed -i.bak "s/export KUBERNETES_VERSION=\".*\"/export KUBERNETES_VERSION=\"$KUBERNETES_VERSION\"/" "$ENV_FILE"
rm -f "$ENV_FILE.bak"
KUBERNETES_NEXT_PATCH=$(echo "$KUBERNETES_VERSION" | awk -F. '{print $1"."$2"."$3+1}')
sed -E -i.bak "s/(upgrade-k8s --to )[0-9]+\.[0-9]+\.[0-9]+/\1${KUBERNETES_NEXT_PATCH}/g" "docs/talos.md"
rm -f "docs/talos.md.bak"

# Update kubelet image in Talos configuration files
CONTROLPLANE_FILE="config/quantum-talos/controlplane.yaml"
WORKER_FILE="config/quantum-talos/worker.yaml"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -f "$CONTROLPLANE_FILE" ]; then
    echo ""
    if confirm "Update Kubernetes images in $CONTROLPLANE_FILE to v$KUBERNETES_VERSION?"; then
        # Create backup with timestamp
        cp "$CONTROLPLANE_FILE" "$CONTROLPLANE_FILE.backup.$TIMESTAMP"
        echo "📦 Backup created: $CONTROLPLANE_FILE.backup.$TIMESTAMP"
        # Update kubelet image
        sed -i.bak "s|ghcr.io/siderolabs/kubelet:v[0-9.]*|ghcr.io/siderolabs/kubelet:v${KUBERNETES_VERSION}|g" "$CONTROLPLANE_FILE"
        # Update kube-apiserver image
        sed -i.bak "s|registry.k8s.io/kube-apiserver:v[0-9.]*|registry.k8s.io/kube-apiserver:v${KUBERNETES_VERSION}|g" "$CONTROLPLANE_FILE"
        # Update kube-controller-manager image
        sed -i.bak "s|registry.k8s.io/kube-controller-manager:v[0-9.]*|registry.k8s.io/kube-controller-manager:v${KUBERNETES_VERSION}|g" "$CONTROLPLANE_FILE"
        # Update kube-proxy image
        sed -i.bak "s|registry.k8s.io/kube-proxy:v[0-9.]*|registry.k8s.io/kube-proxy:v${KUBERNETES_VERSION}|g" "$CONTROLPLANE_FILE"
        # Update kube-scheduler image
        sed -i.bak "s|registry.k8s.io/kube-scheduler:v[0-9.]*|registry.k8s.io/kube-scheduler:v${KUBERNETES_VERSION}|g" "$CONTROLPLANE_FILE"
        rm -f "$CONTROLPLANE_FILE.bak"
        echo "✓ Updated Kubernetes images in $CONTROLPLANE_FILE"
    else
        echo "⊘ Skipped $CONTROLPLANE_FILE update"
    fi
else
    echo "⚠ $CONTROLPLANE_FILE not found, skipping"
fi

if [ -f "$WORKER_FILE" ]; then
    if confirm "Update kubelet image in $WORKER_FILE to v$KUBERNETES_VERSION?"; then
        # Create backup with timestamp
        cp "$WORKER_FILE" "$WORKER_FILE.backup.$TIMESTAMP"
        echo "📦 Backup created: $WORKER_FILE.backup.$TIMESTAMP"
        sed -i.bak "s|ghcr.io/siderolabs/kubelet:v[0-9.]*|ghcr.io/siderolabs/kubelet:v${KUBERNETES_VERSION}|g" "$WORKER_FILE"
        rm -f "$WORKER_FILE.bak"
        echo "✓ Updated kubelet image in $WORKER_FILE"
    else
        echo "⊘ Skipped $WORKER_FILE update"
    fi
else
    echo "⚠ $WORKER_FILE not found, skipping"
fi
# Get latest Flux version
FLUX_VERSION=$(curl -s https://api.github.com/repos/fluxcd/flux2/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "Flux version: $FLUX_VERSION"
sed -i.bak "s/export FLUX_VERSION=\".*\"/export FLUX_VERSION=\"$FLUX_VERSION\"/" "$ENV_FILE"
rm -f "$ENV_FILE.bak"

# Get latest Cilium version
CILIUM_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "Cilium version: $CILIUM_VERSION"
sed -i.bak "s/export CILIUM_VERSION=\".*\"/export CILIUM_VERSION=\"$CILIUM_VERSION\"/" "$ENV_FILE"
rm -f "$ENV_FILE.bak"

# Get latest Gateway API version
API_GATEWAY_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "Gateway API version: $API_GATEWAY_VERSION"

# Update Gateway API version in documentation
sed -E -i.bak "s#(gateway-api/releases/download/v)[0-9]+\.[0-9]+\.[0-9]+#\1${API_GATEWAY_VERSION}#" "$API_GATEWAY_DOC"
rm -f "$API_GATEWAY_DOC.bak"

# Get latest Tailscale Operator version
TAILSCALE_VERSION=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "Tailscale Operator version: $TAILSCALE_VERSION"

# Update Tailscale Operator chart version in HelmRelease
TAILSCALE_CHART_VERSION=$(curl -s https://pkgs.tailscale.com/helmcharts/index.yaml | awk '/^[[:space:]]+tailscale-operator:/{in_chart=1; next} in_chart && /^[[:space:]]+version:[[:space:]]/{print $2; exit}')
echo "Tailscale chart version: $TAILSCALE_CHART_VERSION"
sed -E -i.bak "s#(^[[:space:]]*version:[[:space:]]*\")[0-9]+\.[0-9]+\.[0-9]+(\"$)#\1${TAILSCALE_CHART_VERSION}\2#" "$TAILSCALE_RELEASE_FILE"
rm -f "$TAILSCALE_RELEASE_FILE.bak"

# Update README version badges
sed -E -i.bak "s#(badge/Kubernetes-v)[0-9]+\.[0-9]+\.[0-9]+#\1${KUBERNETES_VERSION}#" "$README_FILE"
sed -E -i.bak "s#(badge/Talos-v)[0-9]+\.[0-9]+\.[0-9]+#\1${TALOS_VERSION}#" "$README_FILE"
sed -E -i.bak "s#(badge/FluxCD-v)[0-9]+\.[0-9]+\.[0-9]+#\1${FLUX_VERSION}#" "$README_FILE"
sed -E -i.bak "s#(badge/Cilium-v)[0-9]+\.[0-9]+\.[0-9]+#\1${CILIUM_VERSION}#" "$README_FILE"
rm -f "$README_FILE.bak"

echo ""
echo "✅ Version update complete!"
