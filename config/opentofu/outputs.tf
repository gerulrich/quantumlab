output "bucket_name" {
  description = "Name of the created bucket"
  value       = oci_objectstorage_bucket.backups.name
}

output "bucket_namespace" {
  description = "OCI Object Storage namespace (required for S3-compatible API calls)"
  value       = data.oci_objectstorage_namespace.ns.namespace
}

output "s3_endpoint" {
  description = "S3-compatible endpoint for Velero"
  value       = "https://${data.oci_objectstorage_namespace.ns.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
}

output "tailscale_operator_oauth_client_id" {
  description = "Tailscale OAuth client ID for the Kubernetes operator"
  value       = tailscale_oauth_client.k8s_operator.id
}

output "tailscale_operator_oauth_client_secret" {
  description = "Tailscale OAuth client secret for the Kubernetes operator (sensitive)"
  value       = tailscale_oauth_client.k8s_operator.key
  sensitive   = true
}

output "cloudflare_tunnel_id" {
  description = "Cloudflare Zero Trust tunnel ID (null if cloudflare_enabled is false)"
  value       = var.cloudflare_enabled ? cloudflare_zero_trust_tunnel_cloudflared.quantum[0].id : null
}

output "cloudflare_tunnel_token_secret_json" {
  description = "Cloudflare tunnel credentials as JSON (ready for Kubernetes Secret creation)"
  value = jsonencode({
    AccountTag = var.cloudflare_account_id
    TunnelID   = cloudflare_zero_trust_tunnel_cloudflared.quantum[0].id
    TunnelSecret = cloudflare_zero_trust_tunnel_cloudflared.quantum[0].tunnel_secret
  })
  sensitive = true
}

# GitHub Actions Secrets
output "github_secrets_created" {
  description = "GitHub Actions secrets created in repositories"
  value = {
    for repo in ["gerulrich/quantumlab", "gerulrich/ledfx", "gerulrich/qmusic", "gerulrich/qvideo"] : repo => {
      DOCKERHUB_USERNAME = github_actions_secret.dockerhub_username[repo].secret_name
      DOCKERHUB_TOKEN    = github_actions_secret.dockerhub_token[repo].secret_name
      WEBHOOK_URL        = github_actions_secret.webhook_url[repo].secret_name
      TS_OAUTH_CLIENT_ID = github_actions_secret.ts_oauth_client_id[repo].secret_name
      TS_OAUTH_SECRET    = github_actions_secret.ts_oauth_secret[repo].secret_name
    }
  }
}
