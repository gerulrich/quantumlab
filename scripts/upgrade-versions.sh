#!/bin/bash

# Update versions in quantum-env.sh
ENV_FILE="scripts/quantum-env.sh"
README_FILE="README.md"
API_GATEWAY_DOC="docs/setup/cilium-api-gateway.md"
TAILSCALE_RELEASE_FILE="helm/tailscale-operator/release.yaml"

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
