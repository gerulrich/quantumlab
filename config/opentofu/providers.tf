# ============================================================================
# OpenTofu / Terraform configuration for Homelab
# ============================================================================

terraform {
  backend "s3" {
    bucket                      = "opentofu-state-homelab"
    key                         = "homelab/terraform.tfstate"
    region                      = "us-ashburn-1"
    use_path_style              = true
    skip_s3_checksum            = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.10.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.28.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.18.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.103.0"
    }
  }
}

provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_id
}

# Retrieves the tenancy namespace in OCI
# The namespace is required for all Object Storage operations
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
  tailnet             = var.tailscale_tailnet
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent       = false
    username    = "root"
    private_key = file(pathexpand(var.proxmox_ssh_private_key_path))
  }
}

