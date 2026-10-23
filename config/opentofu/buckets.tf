# ============================================================================
# Object Storage Bucket
# ============================================================================

# Create an Object Storage bucket to store backups
# Configured with versioning suspended and no public access
resource "oci_objectstorage_bucket" "homelab_backup_bucket" {
  name           = "homelab-backups"
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  versioning     = "Disabled"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

# Create an Object Storage bucket to store configuration files
resource "oci_objectstorage_bucket" "homelab_configuration_bucket" {
  name           = "homelab-config"
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  versioning     = "Disabled"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

# Create an Object Storage bucket to store general data
resource "oci_objectstorage_bucket" "homelab_data_bucket" {
  name           = "homelab-data"
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  versioning     = "Disabled"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}
