#
## Base resource collection
#

## generate a unique id for resources that may require this
resource "random_id" "uniqid" {
  byte_length = 2
}

data "azuread_client_config" "this" {}
data "azurerm_client_config" "this" {}


## service account to manage this subscription
resource "azuread_application" "serviceAccount1" {
  display_name = "eurapp-${var.subscription_name}-${random_id.uniqid.hex}"
  owners       = [data.azuread_client_config.this.object_id]
}

resource "azuread_application_password" "serviceAccount1" {
  application_object_id = azuread_application.serviceAccount1.object_id
}

resource "azuread_service_principal" "serviceAccount1" {
  application_id = azuread_application.serviceAccount1.application_id
  owners         = [data.azuread_client_config.this.object_id]
  description    = "eurapp-${var.subscription_name}-${random_id.uniqid.hex}"
}

## Export crendentials to: pipeline config
resource "local_file" "azurerc" {
  filename        = ".svcaccount.${var.subscription_name}"
  file_permission = "0600"
  content         = <<EOF
echo this should go into a pipeline configuration
export ARM_ENVIRONMENT="public"
export ARM_TENANT_ID="${data.azuread_client_config.this.tenant_id}"
export ARM_CLIENT_ID="${azuread_application.serviceAccount1.application_id}"
export ARM_CLIENT_SECRET="${azuread_application_password.serviceAccount1.value}"
EOF
#export ARM_SUBSCRIPTION_ID="${azurerm_subscription.subscription1.subscription_id}"
}
