# ============================================================================
# OpenTofu / Terraform configuration for Homelab backups on OCI
# ============================================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.7.0"
    }
  }
}

provider "oci" {
  region = var.region
}

# ============================================================================
# Data Sources
# ============================================================================

# Retrieves the tenancy namespace in OCI
# The namespace is required for all Object Storage operations
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

# ============================================================================
# Object Storage Bucket
# ============================================================================

# Create an Object Storage bucket to store backups
# Configured with versioning suspended and no public access
resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_id
  name           = var.bucket_name
  namespace      = data.oci_objectstorage_namespace.ns.namespace

  versioning     = "Suspended"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

# ============================================================================
# IAM policies for lifecycle operations
# ============================================================================

# Grants permissions to the Object Storage service to execute lifecycle policies
# (ARCHIVE and DELETE) on objects in the bucket
resource "oci_identity_policy" "objectstorage_lifecycle_service" {
  compartment_id = var.tenancy_id                    # Created at the tenancy level
  name           = "homelab-objectstorage-lifecycle-${var.region}"  # Name includes region
  description    = "Allows Object Storage lifecycle service to archive/delete objects for the homelab bucket"

  # Allow the regional Object Storage service to manage the object-family
  # but only for the specific bucket (target.bucket.name)
  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment id ${var.compartment_id} where target.bucket.name='${var.bucket_name}'",
  ]
}

# ============================================================================
# Bucket lifecycle policies
# ============================================================================

# Define automatic rules to manage objects based on age
# Objects will be archived after the configured number of days and deleted after the configured number of days
resource "oci_objectstorage_object_lifecycle_policy" "backups_policy" {
  bucket    = oci_objectstorage_bucket.backups.name  # Bucket donde se aplica la política
  namespace = data.oci_objectstorage_namespace.ns.namespace
  depends_on = [oci_identity_policy.objectstorage_lifecycle_service]  # Espera a que existan los permisos

  # Rule 1: Archive objects after N days
  # Archived objects are moved to a cheaper tier (Archive Storage)
  rules {
    action      = "ARCHIVE"                          # Action: archive
    is_enabled  = true                                # Rule enabled
    name        = "archive-after-${var.archive_after_days}-days"  # Description (e.g., archive-after-7-days)
    target      = "objects"                          # Applies to all objects
    time_amount = var.archive_after_days              # Number of days (default: 7)
    time_unit   = "DAYS"                             # Time unit
  }

  # Rule 2: Delete objects after N days
  # Archived objects are permanently deleted after this period
  rules {
    action      = "DELETE"                           # Action: delete
    is_enabled  = true                                # Rule enabled
    name        = "delete-after-${var.delete_after_days}-days"  # Description (e.g., delete-after-30-days)
    target      = "objects"                          # Applies to all objects
    time_amount = var.delete_after_days               # Number of days (default: 30)
    time_unit   = "DAYS"                             # Time unit
  }
}
