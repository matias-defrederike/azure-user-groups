# Access the configuration of the currently authenticated Azure subscription
data "azurerm_client_config" "current" {}

# Create the Entra ID Application (App Registration)
resource "azuread_application" "app" {
  display_name = "github-actions-${var.app_name}"
  owners = [data.azurerm_client_config.current.object_id]
}

# Create the Service Principal linked to the Application
resource "azuread_service_principal" "sp" {
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = false
  owners = [data.azurerm_client_config.current.object_id]
}

# Assign the "Contributor" role to the Service Principal scoped to the Resource Group
resource "azurerm_role_assignment" "contributor_assignment" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id = azuread_service_principal.sp.object_id
}

# Create the Federated Identity Credential for GitHub Actions (OIDC)
resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application.app.id
  display_name   = "github-actions-deploy"
  description    = "Allows GitHub Actions to authenticate using OIDC for deploying to Azure Container Apps"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"

  # Constructs the exact subject string expected by GitHub Actions
  subject = "repo:${var.github_username}/${var.github_repository}:ref:refs/heads/main"
}
