# 5. Output the generated URL at the end
output "app_url" {
  description = "The URL (FQDN) to access Nginx"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}