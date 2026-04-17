# ============================================================================
# Cloudflare Tunnel and DNS
# ============================================================================

# Generates the shared secret used to authenticate the Cloudflare tunnel.
resource "random_password" "tunnel_secret" {
  length = 64
}

# Creates the Cloudflare Zero Trust tunnel used by the cluster.
resource "cloudflare_zero_trust_tunnel_cloudflared" "quantum" {
  
  count = var.cloudflare_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  name       = "quantum-k8s-tunnel"
  config_src = "local"
  tunnel_secret = base64sha256(random_password.tunnel_secret.result)

  lifecycle {
    ignore_changes = [tunnel_secret]
  }
}

# Publishes DNS CNAME records that route hostnames through the tunnel.
resource "cloudflare_dns_record" "tunnel_routes" {
  for_each = var.cloudflare_enabled ? toset([
    "ng" # nginx ingress
  ]) : toset([])

  zone_id = var.cloudflare_zone_id
  name    = "${each.value}.${var.cloudflare_domain_name}"
  ttl     = 1
  type    = "CNAME"
  proxied = true
  content = "${cloudflare_zero_trust_tunnel_cloudflared.quantum[0].id}.cfargotunnel.com"
  comment = "Managed by OpenTofu for tunnel ${cloudflare_zero_trust_tunnel_cloudflared.quantum[0].name}"
}
