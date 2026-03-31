# set up environment variables talosctl and kubectl

# Versions
export TALOS_VERSION="1.12.6"
export KUBERNETES_VERSION="1.35.3"
export FLUX_VERSION="2.8.3"
export CILIUM_VERSION="1.19.2"
export SCHEMATIC_ID=a2e824fa8b6d72b70f9076cebd483a76cd56a07a0a81372611a8ed6fe3b6b95e

# Cluster configuration
export CONTROL_PLANE_IP=10.10.10.194
export CONTROL_PLANE_MAC="52:54:00:1a:c7:e5"
export WORKER_IP=10.10.10.173
export WORKER_MAC="52:54:00:f3:be:40"
export KUBECONFIG=$PWD/kubeconfig
export TALOSCONFIG=$PWD/config/quantum-talos/talosconfig
export SOPS_AGE_KEY_FILE=$PWD/age.key
export PATH=$PATH:$PWD/bin

# ============================================================================
# OpenTofu S3 Backend Configuration (OCI Object Storage)
# ============================================================================
# Load remote backend credentials if the file exists
# Used by: tofu init, tofu plan, tofu apply in config/opentofu/

# Determine the script directory (bash and zsh compatible)
if [[ -n "${BASH_SOURCE:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # zsh: use $0
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_CONFIG_FILE="$REPO_ROOT/config/opentofu/terraform.tfvars.backend"

if [[ -f "$BACKEND_CONFIG_FILE" ]]; then
  export TF_VAR_s3_endpoint=$(sed -n 's/^s3_endpoint[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$BACKEND_CONFIG_FILE" 2>/dev/null || echo "")
  export AWS_ACCESS_KEY_ID=$(sed -n 's/^s3_access_key_id[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$BACKEND_CONFIG_FILE" 2>/dev/null || echo "")
  export AWS_SECRET_ACCESS_KEY=$(sed -n 's/^s3_secret_access_key[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$BACKEND_CONFIG_FILE" 2>/dev/null || echo "")
  # Debug: Show whether the variables loaded correctly (uncomment for troubleshooting)
  # echo "[quantum-env.sh] OpenTofu backend config loaded:"
  # echo "  - s3_endpoint: ${TF_VAR_s3_endpoint}"
  # echo "  - AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:10}****"
fi
