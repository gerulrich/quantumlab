#!/bin/bash

# Update versions in quantum-env.sh
ENV_FILE="scripts/quantum-env.sh"
README_FILE="README.md"

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
CILIUM_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium/releases/latest | jq -r .tag_name)
echo "Cilium version: $CILIUM_VERSION"
sed -i.bak "s/export CILIUM_VERSION=\".*\"/export CILIUM_VERSION=\"$CILIUM_VERSION\"/" "$ENV_FILE"
rm -f "$ENV_FILE.bak"

# Update README version badges
sed -E -i.bak "s#(badge/Kubernetes-v)[0-9]+\.[0-9]+\.[0-9]+#\1${KUBERNETES_VERSION}#" "$README_FILE"
sed -E -i.bak "s#(badge/Talos-v)[0-9]+\.[0-9]+\.[0-9]+#\1${TALOS_VERSION}#" "$README_FILE"
sed -E -i.bak "s#(badge/FluxCD-v)[0-9]+\.[0-9]+\.[0-9]+#\1${FLUX_VERSION}#" "$README_FILE"
rm -f "$README_FILE.bak"
