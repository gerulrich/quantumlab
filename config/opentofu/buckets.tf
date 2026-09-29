# ============================================================================
# Object Storage Bucket
# ============================================================================

# Create an Object Storage bucket to store backups
# Configured with versioning suspended and no public access
resource "oci_objectstorage_bucket" "backups" {
  name           = "backups-homelab"
  compartment_id = var.compartment_id
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
  compartment_id = var.tenancy_id
  name           = "homelab-objectstorage-lifecycle-${var.region}"
  description    = "Allows Object Storage lifecycle service to archive/delete objects for the homelab bucket"

  # Allow the regional Object Storage service to manage the object-family
  # but only for the specific bucket (target.bucket.name)
  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment id ${var.compartment_id} where target.bucket.name=backups-homelab",
  ]
}

resource "oci_objectstorage_bucket" "homelab_config" {
  name           = "homelab-config"
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  versioning     = "Disabled"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

resource "oci_objectstorage_bucket" "pocketid_images" {
  name           = "pocketid-images"
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  versioning     = "Disabled"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}
