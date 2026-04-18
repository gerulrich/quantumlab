#!/bin/bash
# ============================================================================
# Script: Create OpenTofu State Bucket
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
STATE_BUCKET_NAME="${STATE_BUCKET_NAME:-opentofu-state-homelab}"
OCI_CONFIG_FILE="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"
OCI_PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"
REGION="${REGION:-}"
TFVARS_FILE="$REPO_ROOT/config/opentofu/terraform.tfvars"
TFVARS_EXAMPLE_FILE="$REPO_ROOT/config/opentofu/terraform.tfvars.example"

source "$REPO_ROOT/scripts/quantum-env.sh"

get_oci_config_value() {
  awk -F= -v k="$1" '$1 ~ "^[[:space:]]*" k "[[:space:]]*$" {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' "$OCI_CONFIG_FILE"
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}OpenTofu State Bucket Creation Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Verify that the OCI CLI is available
if ! command -v oci &> /dev/null; then
  echo -e "${RED}Error: OCI CLI not found${NC}"
  echo "Install with: bash scripts/download-tools.sh"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq not found${NC}"
  echo "Install with: bash scripts/download-tools.sh"
  exit 1
fi

# Verify that OCI CLI credentials are configured
if [[ ! -f "$OCI_CONFIG_FILE" ]]; then
  echo -e "${RED}Error: OCI CLI credentials not found${NC}"
  echo "Configure with: oci setup config"
  exit 1
fi

echo -e "${YELLOW}Gathering OCI information...${NC}"

ensure_tfvars_file() {
  if [[ -f "$TFVARS_FILE" ]]; then
    return
  fi

  if [[ ! -f "$TFVARS_EXAMPLE_FILE" ]]; then
    echo -e "${RED}Error: Terraform example variables file not found${NC}"
    echo "Missing file: $TFVARS_EXAMPLE_FILE"
    exit 1
  fi

  cp "$TFVARS_EXAMPLE_FILE" "$TFVARS_FILE"
  chmod 600 "$TFVARS_FILE"
  echo -e "${GREEN}✓ Created $TFVARS_FILE from terraform.tfvars.example${NC}"
}

ensure_tfvars_file

# Retrieve the tenancy namespace
NAMESPACE=$(oci os ns get --query 'data' --raw-output 2>/dev/null || echo "")
if [[ -z "$NAMESPACE" ]]; then
  echo -e "${RED}Error: Could not retrieve OCI namespace${NC}"
  echo "Make sure OCI credentials are properly configured"
  exit 1
fi

echo -e "${GREEN}✓ Namespace: $NAMESPACE${NC}"

# Load missing values from OCI config profile
if [[ -z "$REGION" ]]; then
  REGION="$(get_oci_config_value region)"
fi

TENANCY_ID="$(get_oci_config_value tenancy)"
COMPARTMENT_ID="$(get_oci_config_value compartment_id)"
if [[ -z "$COMPARTMENT_ID" ]]; then
  COMPARTMENT_ID="$TENANCY_ID"
fi

if [[ -z "$COMPARTMENT_ID" ]]; then
  echo -e "${RED}Error: compartment_id/tenancy not found in OCI config profile [$OCI_PROFILE]${NC}"
  exit 1
fi

if [[ -z "$TENANCY_ID" ]]; then
  echo -e "${RED}Error: tenancy not found in OCI config profile [$OCI_PROFILE]${NC}"
  exit 1
fi

if [[ -z "$REGION" ]]; then
  echo -e "${RED}Error: region not found in OCI config profile [$OCI_PROFILE]${NC}"
  exit 1
fi

S3_ENDPOINT="https://$NAMESPACE.compat.objectstorage.$REGION.oraclecloud.com"


echo -e "${GREEN}✓ Compartment: ${COMPARTMENT_ID:0:20}...${NC}"
echo -e "${GREEN}✓ Region: $REGION${NC}"


# Check if the bucket already exists
echo -e "${YELLOW}Checking if bucket already exists...${NC}"
if oci os bucket get --namespace-name "$NAMESPACE" --bucket-name "$STATE_BUCKET_NAME" &>/dev/null; then
  echo -e "${GREEN}✓ Bucket already exists: $STATE_BUCKET_NAME${NC}"
  echo ""
  echo "update terraform.tfvars with backend configuration:"
  echo -e "${GREEN}s3_endpoint = \"$S3_ENDPOINT\"${NC}"
  exit 0
fi

# Create the bucket
echo ""
echo -e "${YELLOW}Creating bucket: $STATE_BUCKET_NAME${NC}"

oci os bucket create \
  --namespace-name "$NAMESPACE" \
  --name "$STATE_BUCKET_NAME" \
  --compartment-id "$COMPARTMENT_ID" \
  --storage-tier Standard \
  --versioning Suspended

if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}✓ Bucket created successfully${NC}"
else
  echo -e "${RED}Error: Failed to create bucket${NC}"
  exit 1
fi

# Show configuration values to copy into tfvars
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Bucket created successfully!${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "update terraform.tfvars with backend configuration:"
echo ""
echo -e "${GREEN}s3_endpoint = \"$S3_ENDPOINT\"${NC}"
echo ""
echo "Then run:"
echo -e "${YELLOW}  source scripts/quantum-env.sh${NC}"
echo -e "${YELLOW}  tofu init${NC}"
echo ""
