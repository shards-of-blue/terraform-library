
output "az_service_principal" {
  value = {
    "client_id" = azuread_application.serviceAccount1.application_id
    "client_secret" = azuread_application_password.serviceAccount1.value
  }
}

output "az_subscription" {
  value = {
    "tenant_id" = data.azuread_client_config.this.tenant_id
    "subscription_id" = azurerm_subscription.subscription1.subscription_id
    "subscription_name" = azurerm_subscription.subscription1.subscription_name
  }
}
