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
    local create_symlink=${4:-true}
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
    
        if [ "$create_symlink" = "true" ]; then
                # Actualizar o crear symlink
                if [ -L "$symlink" ]; then
                        rm "$symlink"
                fi
                ln -s "${tool_name}-${version}" "$symlink"
                echo "✓ ${tool_name} -> ${tool_name}-${version}"
        fi
}

create_tofu_wrapper() {
        local wrapper_path="$PWD/bin/tofu"

        cat > "$wrapper_path" << 'EOF'
#!/usr/bin/env bash

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$BIN_DIR/.." && pwd)"
TFVARS_FILE="$REPO_ROOT/config/opentofu/terraform.tfvars"

if [[ -f "$TFVARS_FILE" ]]; then
    TF_VAR_s3_endpoint=$(sed -n 's/^s3_endpoint[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$TFVARS_FILE" 2>/dev/null || true)
    AWS_ACCESS_KEY_ID=$(sed -n 's/^s3_access_key_id[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$TFVARS_FILE" 2>/dev/null || true)
    AWS_SECRET_ACCESS_KEY=$(sed -n 's/^s3_secret_access_key[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$TFVARS_FILE" 2>/dev/null || true)

    [[ -n "${TF_VAR_s3_endpoint:-}" ]] && export TF_VAR_s3_endpoint
    [[ -n "${AWS_ACCESS_KEY_ID:-}" ]] && export AWS_ACCESS_KEY_ID
    [[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]] && export AWS_SECRET_ACCESS_KEY
fi

args=("$@")
has_chdir=false
is_init=false
has_endpoint_backend=false

for ((i=0; i<${#args[@]}; i++)); do
    arg="${args[$i]}"
    case "$arg" in
        -chdir=*)
            has_chdir=true
            ;;
        -chdir)
            has_chdir=true
            ((i++))
            ;;
        init)
            is_init=true
            ;;
        -backend-config=endpoint=*)
            has_endpoint_backend=true
            ;;
        -backend-config)
            next_arg="${args[$((i+1))]:-}"
            if [[ "$next_arg" == endpoint=* ]]; then
                has_endpoint_backend=true
            fi
            ;;
    esac
done

if [[ "$has_chdir" == false ]]; then
    args=("-chdir=$REPO_ROOT/config/opentofu" "${args[@]}")
fi

if [[ "$is_init" == true ]] && [[ -n "${TF_VAR_s3_endpoint:-}" ]] && [[ "$has_endpoint_backend" == false ]]; then
    args+=("-backend-config=endpoint=$TF_VAR_s3_endpoint")
fi

# Validate backend credentials for init command
if [[ "$is_init" == true ]]; then
    if [[ -z "${TF_VAR_s3_endpoint:-}" ]] || [[ -z "${AWS_ACCESS_KEY_ID:-}" ]] || [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "⚠️  Missing S3 backend credentials in terraform.tfvars" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "" >&2
        echo "Required variables in config/opentofu/terraform.tfvars:" >&2
        [[ -z "${TF_VAR_s3_endpoint:-}" ]] && echo "  ❌ s3_endpoint (uncomment or set the S3-compatible endpoint URL)" >&2
        [[ -z "${AWS_ACCESS_KEY_ID:-}" ]] && echo "  ❌ s3_access_key_id (uncomment or set the S3 access key)" >&2
        [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]] && echo "  ❌ s3_secret_access_key (uncomment or set the S3 secret key)" >&2
        echo "" >&2
        echo "Hint: Run 'source scripts/quantum-env.sh && bash scripts/create-state-bucket.sh' to generate these values." >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        exit 1
    fi
fi

tofu_bin="$(find "$BIN_DIR" -maxdepth 1 -type f -name 'tofu-v*' -print | sort -V | tail -n 1)"
if [[ -z "$tofu_bin" ]]; then
    echo "Error: no se encontró ningún binario versionado tofu-v* en $BIN_DIR" >&2
    exit 1
fi

exec "$tofu_bin" "${args[@]}"
EOF

        chmod +x "$wrapper_path"
        echo "✓ tofu wrapper -> tofu-v* (latest)"
}

create_backups_script() {
                local script_path="$PWD/bin/backup"

                cat > "$script_path" << 'EOF'
#!/usr/bin/env bash
#
# Manage restic backups for the different targets defined in this repo.
#
# Usage:
#   backup list <target> [--keys repo|cluster]
#   backup download <target> [--keys repo|cluster]

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$BIN_DIR/.." && pwd)"
PATH="$BIN_DIR:$PATH"

# Target definitions: "namespace:secretName:repoSecretFile"
TARGET_NAMES="etcd"
target_config() {
    case "$1" in
        etcd) echo "kube-system:talos-etcd-s3-keys:infrastructure/base/controllers/etcd-backup/secrets.yaml" ;;
        *) return 1 ;;
    esac
}

usage() {
    cat <<USAGE
Usage: $(basename "$0") <command> <target> [--keys repo|cluster]

Commands:
    list <target>              List available snapshots
    download <target> [id]     Restore a snapshot to the current directory (default: latest)

Targets:
$(printf '  %s\n' $TARGET_NAMES)

Options:
    --keys <repo|cluster>  Where to read restic/S3 credentials from (default: cluster)
                                                 cluster: read the Secret directly from the Kubernetes cluster
                                                 repo:    decrypt the Secret's sops-encrypted secrets.yaml in this repo
USAGE
    exit 1
}

load_keys_from_cluster() {
    local namespace="$1" secret_name="$2"
    export RESTIC_REPOSITORY="$(kubectl -n "$namespace" get secret "$secret_name" -o jsonpath='{.data.resticRepository}' | base64 --decode)"
    export RESTIC_PASSWORD="$(kubectl -n "$namespace" get secret "$secret_name" -o jsonpath='{.data.resticKey}' | base64 --decode)"
    export AWS_ACCESS_KEY_ID="$(kubectl -n "$namespace" get secret "$secret_name" -o jsonpath='{.data.accessKeyId}' | base64 --decode)"
    export AWS_SECRET_ACCESS_KEY="$(kubectl -n "$namespace" get secret "$secret_name" -o jsonpath='{.data.secretAccessKey}' | base64 --decode)"
}

load_keys_from_repo() {
    local secret_file="$1"
    local secret_path="$REPO_ROOT/$secret_file"
    [[ -f "$secret_path" ]] || { echo "Secret file not found: $secret_path" >&2; exit 1; }

    extract() {
        sops -d --extract "[\"stringData\"][\"$1\"]" "$secret_path"
    }

    export RESTIC_REPOSITORY="$(extract resticRepository)"
    export RESTIC_PASSWORD="$(extract resticKey)"
    export AWS_ACCESS_KEY_ID="$(extract accessKeyId)"
    export AWS_SECRET_ACCESS_KEY="$(extract secretAccessKey)"
}

COMMAND="${1:-}"
TARGET="${2:-}"
[[ -z "$COMMAND" || -z "$TARGET" ]] && usage
shift 2

KEYS_SOURCE="cluster"
SNAPSHOT_ID=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --keys)
            KEYS_SOURCE="${2:-}"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *)
            SNAPSHOT_ID="$1"
            shift
            ;;
    esac
done

TARGET_CONFIG="$(target_config "$TARGET")" || { echo "Unknown target: $TARGET" >&2; usage; }
[[ "$KEYS_SOURCE" == "repo" || "$KEYS_SOURCE" == "cluster" ]] || { echo "Invalid --keys value: $KEYS_SOURCE (expected repo|cluster)" >&2; exit 1; }

IFS=':' read -r NAMESPACE SECRET_NAME SECRET_FILE <<< "$TARGET_CONFIG"

if [[ "$KEYS_SOURCE" == "repo" ]]; then
    load_keys_from_repo "$SECRET_FILE"
else
    load_keys_from_cluster "$NAMESPACE" "$SECRET_NAME"
fi

RESTIC_OPTS=(-o s3.region=us-ashburn-1 -o s3.bucket-lookup=path)

case "$COMMAND" in
    list)
        restic "${RESTIC_OPTS[@]}" snapshots
        ;;
    download)
        restic "${RESTIC_OPTS[@]}" restore "${SNAPSHOT_ID:-latest}" --target .
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        usage
        ;;
esac
EOF

                chmod +x "$script_path"
                rm -f "$PWD/scripts/backups.sh"
                echo "✓ backup -> bin/backup (scripts/backups.sh eliminado)"
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

# restic
RESTIC_VERSION=$(curl -s https://api.github.com/repos/restic/restic/releases/latest | jq -r .tag_name)
RESTIC_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$(uname -m)" in
    x86_64|amd64) RESTIC_ARCH=amd64 ;;
    arm64|aarch64) RESTIC_ARCH=arm64 ;;
    i386|i686) RESTIC_ARCH=386 ;;
    armv7l|armv7) RESTIC_ARCH=arm ;;
    ppc64le|riscv64|s390x) RESTIC_ARCH=$(uname -m) ;;
    *) echo "Arquitectura no soportada por restic: $(uname -m)" >&2; exit 1 ;;
esac
download_versioned_binary "restic" "$RESTIC_VERSION" "
    curl -L --fail -o restic_${RESTIC_VERSION#v}_${RESTIC_OS}_${RESTIC_ARCH}.bz2 https://github.com/restic/restic/releases/download/${RESTIC_VERSION}/restic_${RESTIC_VERSION#v}_${RESTIC_OS}_${RESTIC_ARCH}.bz2
    bunzip2 restic_${RESTIC_VERSION#v}_${RESTIC_OS}_${RESTIC_ARCH}.bz2
    mv restic_${RESTIC_VERSION#v}_${RESTIC_OS}_${RESTIC_ARCH} restic-${RESTIC_VERSION}
"

# talosctl
TALOSCTL_VERSION=$(curl -s https://api.github.com/repos/siderolabs/talos/releases/latest | jq -r .tag_name)
download_versioned_binary "talosctl" "$TALOSCTL_VERSION" "
    curl -L --fail -o talosctl-${TALOSCTL_VERSION} https://github.com/siderolabs/talos/releases/download/${TALOSCTL_VERSION}/talosctl-${OS}-${CLI_ARCH}
"

# OpenTofu
OPENTOFU_VERSION=$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest | jq -r .tag_name)
download_versioned_binary "tofu" "$OPENTOFU_VERSION" "
    curl -L --fail -o tofu_${OPENTOFU_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz https://github.com/opentofu/opentofu/releases/download/${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
    tar xzf tofu_${OPENTOFU_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
    mv tofu tofu-${OPENTOFU_VERSION}
    rm tofu_${OPENTOFU_VERSION#v}_${OS}_${CLI_ARCH}.tar.gz
" false
create_tofu_wrapper
create_backups_script

# OCI CLI
OCI_CLI_VERSION=$(curl -s https://api.github.com/repos/oracle/oci-cli/releases/latest | jq -r .tag_name)
download_versioned_binary "oci" "$OCI_CLI_VERSION" "
    OCI_INSTALL_DIR=\$PWD/oci-cli-${OCI_CLI_VERSION#v}
    OCI_SCRIPT_DIR=\$PWD/oci-cli-scripts-${OCI_CLI_VERSION#v}

    curl -L --fail -o oci-install.sh https://raw.githubusercontent.com/oracle/oci-cli/${OCI_CLI_VERSION}/scripts/install/install.sh
    bash oci-install.sh --accept-all-defaults --install-dir \"\$OCI_INSTALL_DIR\" --exec-dir \"\$PWD\" --script-dir \"\$OCI_SCRIPT_DIR\"
    mv oci oci-${OCI_CLI_VERSION}
    rm -f oci-install.sh
"

# Limpiar archivos innecesarios
rm -f $PWD/bin/LICENSE $PWD/bin/README.md $PWD/bin/CHANGELOG.md

echo ""
echo "✓ Todas las herramientas han sido instaladas correctamente"