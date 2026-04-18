# ============================================================================
# Tailscale ACL and Network Policy Configuration
# ============================================================================
# Defines tag ownership and access control policies for the Tailscale network
resource "tailscale_acl" "policy" {
  overwrite_existing_content = false
  acl = templatefile("${path.module}/tailscale-policy.hujson.tftpl", {
    tailscale_internal_subnet = var.tailscale_internal_subnet
  })
}

# ============================================================================
# Tailscale OAuth Client for the Kubernetes Operator
# ============================================================================
# Creates an OAuth client (client_id + client_secret) for the tailscale-operator.
# The operator uses these credentials to manage devices and auth keys on the tailnet.
# Required scopes:
#   - auth_keys: provision node keys
#   - devices:core: manage devices and their properties
#   - devices:routes: manage subnet routes for autoApprovers
#   - services: manage service tags if needed
resource "tailscale_oauth_client" "k8s_operator" {
  description = "talos tailscale operator - opentofu"
  tags        = ["tag:k8s-operator"]
  scopes      = ["auth_keys", "devices:core", "devices:routes", "services"]
}