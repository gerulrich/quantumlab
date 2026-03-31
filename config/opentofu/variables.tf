variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  description = "OCID of the compartment where the bucket will be created"
  type        = string
}

variable "tenancy_id" {
  description = "Tenancy OCID (root compartment), required for IAM policies"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Object Storage bucket"
  type        = string
  default     = "backups-homelab"
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
