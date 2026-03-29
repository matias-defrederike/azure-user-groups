# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics Workspace (Mandatory requirement for Container Apps)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "logs-${var.app_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App Environment (Managed environment where the app will run)
resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${var.app_name}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

# Container App and IP restriction
resource "azurerm_container_app" "app" {
  name                         = "app-${var.app_name}"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    container {
      name   = "container-${var.app_name}"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  ingress {
    allow_insecure_connections = true
    external_enabled           = true # Enables external access (Internet)
    target_port                = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }

    ip_security_restriction {
      action           = "Allow"
      name             = "AllowMyIP"
      ip_address_range = var.vpn_public_ip
    }
  }
}

resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "id-aca-acrpull"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# Create the Public ACR (Standard SKU, Admin Disabled)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

# Give Push permissions (AcrPush) ONLY to the GitHub Service Principal
resource "azurerm_role_assignment" "acr_push_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"

  principal_id = azuread_service_principal.sp.object_id
}

# Create the ACR Task to purge old images automatically
# Lifecyle is only possible for premium SKU
resource "azurerm_container_registry_task" "purge" {
  name                  = "PurgeOldImages"
  container_registry_id = azurerm_container_registry.acr.id

  platform {
    os = "Linux"
  }

  # Maps to the CLI's --schedule "0 0 * * *"
  timer_trigger {
    name     = "daily_purge_schedule"
    schedule = "0 0 * * *"
    enabled  = true
  }

  # Maps to the CLI's --cmd "...". 
  # In Terraform, inline commands are passed via an encoded YAML step.
  encoded_step {
    context_path = "/dev/null" # Maps to --context /dev/null

    task_content = base64encode(<<-EOF
      version: v1.1.0
      steps:
        - cmd: acr purge --filter 'matias-azure-container-app:.*' --keep 10 --untagged
    EOF
    )
  }
}
