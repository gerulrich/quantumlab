# ============================================================================
# GitHub Repository Management
# ============================================================================
# Manages GitHub Actions secrets for specified repositories

# Data sources to reference existing repositories
data "github_repository" "repos" {
  for_each = toset([
    "gerulrich/quantumlab",
    "gerulrich/ledfx",
    "gerulrich/qmusic",
    "gerulrich/qvideo"
  ])
  full_name = each.value
}

# Create GitHub Actions secrets for each repository
resource "github_actions_secret" "dockerhub_username" {
  for_each            = data.github_repository.repos
  repository          = each.value.name
  secret_name         = "DOCKERHUB_USERNAME"
  plaintext_value     = var.github_secrets["DOCKERHUB_USERNAME"].value
}

resource "github_actions_secret" "dockerhub_token" {
  for_each            = data.github_repository.repos
  repository          = each.value.name
  secret_name         = "DOCKERHUB_TOKEN"
  plaintext_value     = var.github_secrets["DOCKERHUB_TOKEN"].value
}

resource "github_actions_secret" "webhook_url" {
  for_each            = data.github_repository.repos
  repository          = each.value.name
  secret_name         = "WEBHOOK_URL"
  plaintext_value     = var.github_secrets["WEBHOOK_URL"].value
}

resource "github_actions_secret" "ts_oauth_client_id" {
  for_each            = data.github_repository.repos
  repository          = each.value.name
  secret_name         = "TS_OAUTH_CLIENT_ID"
  plaintext_value     = var.github_secrets["TS_OAUTH_CLIENT_ID"].value
}

resource "github_actions_secret" "ts_oauth_secret" {
  for_each            = data.github_repository.repos
  repository          = each.value.name
  secret_name         = "TS_OAUTH_SECRET"
  plaintext_value     = var.github_secrets["TS_OAUTH_SECRET"].value
}
