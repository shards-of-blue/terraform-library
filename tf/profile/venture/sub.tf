#
## Subscription resource collection
#

locals {
  ## make a map of default values from global configuration items
  sub_defaults = {
    billing_account_name = local.confmap.az_default_billing_account_name
    enrollment_account_name = local.confmap.az_default_enrollment_account_name
    workload = local.confmap.az_default_subscription_workload
    mg_association = local.confmap.az_default_mg_association
    storage_account = local.confmap.az_infra_provisioning_storage_account
    storage_resgroup = local.confmap.az_infra_provisioning_resource_group
    infra_provisioning_storage_account = local.confmap.az_infra_provisioning_storage_account
    infra_provisioning_resource_group = local.confmap.az_infra_provisioning_resource_group
  }

  ## merge defaults with the parameters that were passed in
  msubargs = merge(local.sub_defaults, var.args)
}

## Lookup billing and enrollment scope
data "azurerm_billing_enrollment_account_scope" "billing" {
  billing_account_name    = local.msubargs.billing_account_name
  enrollment_account_name = local.msubargs.enrollment_account_name
}

## manage subscription
resource "azurerm_subscription" "subscription1" {
  subscription_name = var.name
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.billing.id
  workload          = local.msubargs.workload
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
  count = local.msubargs.mg_association != "" ? 1 : 0
  name  = local.msubargs.mg_association
}

resource "azurerm_management_group_subscription_association" "mgAssociation1" {
  count               = local.msubargs.mg_association != "" ? 1 : 0
  management_group_id = data.azurerm_management_group.mGroup1[0].id
  subscription_id     = data.azurerm_subscription.subscription1.id
}

data "azurerm_storage_account" "commonStorageAccount1" {
  provider            = azurerm.infrasupport
  name                = local.msubargs.infra_provisioning_storage_account
  resource_group_name = local.msubargs.infra_provisioning_resource_group
}

## assign serviceaccount read/write data role to common provisioning storage account
resource "azurerm_role_assignment" "serviceRole2" {
  scope                = data.azurerm_storage_account.commonStorageAccount1.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.serviceAccount1.object_id
}
