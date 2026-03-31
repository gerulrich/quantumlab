#!/bin/bash
# ============================================================================
# Script: Create OpenTofu State Bucket
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$REPO_ROOT/scripts/quantum-env.sh"

STATE_BUCKET_NAME="${STATE_BUCKET_NAME:-opentofu-state-homelab}"
REGION="${REGION:-us-ashburn-1}"

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

# Verify that OCI CLI credentials are configured
if [[ -z "${OCI_CLI_CONFIG_FILE:-}" && ! -f ~/.oci/config ]]; then
  echo -e "${RED}Error: OCI CLI credentials not found${NC}"
  echo "Configure with: oci session authenticate"
  exit 1
fi

echo -e "${YELLOW}Gathering OCI information...${NC}"

# Retrieve the tenancy namespace
NAMESPACE=$(oci os ns get --query 'data' --raw-output 2>/dev/null || echo "")
if [[ -z "$NAMESPACE" ]]; then
  echo -e "${RED}Error: Could not retrieve OCI namespace${NC}"
  echo "Make sure OCI credentials are properly configured"
  exit 1
fi

echo -e "${GREEN}✓ Namespace: $NAMESPACE${NC}"

# Get the tenancy compartment ID (default)
# If configured in terraform.tfvars, use it; otherwise exit with warning
if [[ -f "$REPO_ROOT/config/opentofu/terraform.tfvars" ]]; then
  COMPARTMENT_ID=$(grep "compartment_id = " "$REPO_ROOT/config/opentofu/terraform.tfvars" | cut -d'"' -f2)
else
  echo -e "${YELLOW}Warning: terraform.tfvars not found${NC}"
  echo "Please configure it first with your OCI compartment ID"
  exit 1
fi

if [[ -z "$COMPARTMENT_ID" ]]; then
  echo -e "${RED}Error: compartment_id not found in terraform.tfvars${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Compartment: ${COMPARTMENT_ID:0:20}...${NC}"

# Check if the bucket already exists
echo -e "${YELLOW}Checking if bucket already exists...${NC}"
if oci os bucket get --namespace-name "$NAMESPACE" --bucket-name "$STATE_BUCKET_NAME" &>/dev/null; then
  echo -e "${GREEN}✓ Bucket already exists: $STATE_BUCKET_NAME${NC}"
  echo ""
  echo "Configuration for terraform.tfvars.backend (required fields):"
  echo -e "${GREEN}s3_endpoint = \"https://$NAMESPACE.compat.objectstorage.$REGION.oraclecloud.com\"${NC}"
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
echo "Add this value to config/opentofu/terraform.tfvars.backend:"
echo ""
echo -e "${GREEN}s3_endpoint = \"https://$NAMESPACE.compat.objectstorage.$REGION.oraclecloud.com\"${NC}"
echo ""
echo "Then run:"
echo -e "${YELLOW}  source scripts/quantum-env.sh${NC}"
echo -e "${YELLOW}  cd config/opentofu${NC}"
echo -e "${YELLOW}  tofu init -backend-config=\"endpoint=\$TF_VAR_s3_endpoint\"${NC}"
echo ""
