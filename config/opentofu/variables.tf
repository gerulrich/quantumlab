variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "s3_endpoint" {
  description = "S3-compatible endpoint for OCI Object Storage backend"
  type        = string
  default     = null
  nullable    = true
}

variable "s3_access_key_id" {
  description = "S3 access key ID for backend authentication"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "s3_secret_access_key" {
  description = "S3 secret access key for backend authentication"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "compartment_id" {
  description = "OCID of the compartment where the bucket will be created"
  type        = string
}

variable "tenancy_id" {
  description = "Tenancy OCID (root compartment), required for IAM policies"
  type        = string
}

variable "archive_after_days" {
  description = "Days after which objects are moved to Archive tier"
  type        = number
  default     = 7
}

variable "delete_after_days" {
  description = "Days after which objects are permanently deleted"
  type        = number
  default     = 30
}

variable "tailscale_oauth_client_id" {
  description = "Tailscale OAuth client ID for the Kubernetes operator"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "tailscale_oauth_client_secret" {
  description = "Tailscale OAuth client secret for the Kubernetes operator"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "Tailscale tailnet name"
  type        = string
}

variable "tailscale_internal_subnet" {
  description = "Internal subnet for Tailscale autoApprovers routes (e.g., 192.168.10.0/24)"
  type        = string
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL (e.g., https://proxmox.example.com:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_private_key_path" {
  description = "Path to the SSH private key used by the Proxmox provider"
  type        = string
}

variable "cloudflare_enabled" {
  description = "Enable management of the Cloudflare tunnel and DNS records"
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID used by Zero Trust Tunnel resources"
  type        = string
  default     = null
  nullable    = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID used for DNS records"
  type        = string
  default     = null
  nullable    = true
}

variable "cloudflare_domain_name" {
  description = "Base domain name for Cloudflare DNS records (e.g., example.com)"
  type        = string
  nullable    = false
}