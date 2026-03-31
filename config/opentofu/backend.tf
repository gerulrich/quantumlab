# ============================================================================
# OpenTofu Remote State Backend Configuration
# ============================================================================
# Configure OpenTofu remote state storage in OCI Object Storage
# using the S3-compatible protocol.

terraform {
  backend "s3" {
    bucket = "opentofu-state-homelab"
    key    = "homelab/terraform.tfstate"
    region = "us-ashburn-1"
    use_path_style              = true
    skip_s3_checksum            = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}
