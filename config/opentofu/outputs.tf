output "bucket_name" {
  description = "Name of the created bucket"
  value       = oci_objectstorage_bucket.backups.name
}

output "bucket_namespace" {
  description = "Object Storage namespace"
  value       = data.oci_objectstorage_namespace.ns.namespace
}

output "s3_endpoint" {
  description = "S3-compatible endpoint for Velero"
  value       = "https://${data.oci_objectstorage_namespace.ns.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
}
