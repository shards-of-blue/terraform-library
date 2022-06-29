#
## Subscription resource collection
#

data "azurerm_billing_enrollment_account_scope" "billing" {
  billing_account_name    = var.billing_account_name
  enrollment_account_name = var.enrollment_account_name
}

## manage subscription
resource "azurerm_subscription" "subscription1" {
  subscription_name = var.subscription_name
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.billing.id
  workload          = var.subscription_workload
}

## refresh
data "azurerm_subscription" "subscription1" {
  subscription_id   = azurerm_subscription.subscription1.subscription_id
}

## assign serviceaccount as subscription owner
resource "azurerm_role_assignment" "serviceRole1" {
  scope                = data.azurerm_subscription.subscription1.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.serviceAccount1.object_id
}

## Optional(?): management group association
data "azurerm_management_group" "mGroup1" {
  count = var.mg_association != "" ? 1 : 0
  name  = var.mg_association
}

resource "azurerm_management_group_subscription_association" "mgAssociation1" {
  count               = var.mg_association != "" ? 1 : 0
  management_group_id = data.azurerm_management_group.mGroup1[0].id
  subscription_id     = data.azurerm_subscription.subscription1.id
}

data "azurerm_storage_account" "commonStorageAccount1" {
  provider                 = azurerm.infrasupport
  name                     = var.infra_provisioning_storage_account
  resource_group_name      = var.infra_provisioning_resource_group
}

## assign serviceaccount read/write data role to common provisioning storage account
resource "azurerm_role_assignment" "serviceRole2" {
  scope                = data.azurerm_storage_account.commonStorageAccount1.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.serviceAccount1.object_id
}
