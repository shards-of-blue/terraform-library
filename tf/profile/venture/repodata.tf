#
## Common repo data
#

## generate a unique id for resources that may require this
resource "random_id" "gh_repo_uniqid" {
  byte_length = 8
}

locals {

  reponame = var.name

  repovars = [{
      k = "ARM_SUBSCRIPTION_ID",
      v = data.azurerm_subscription.subscription1.subscription_id, secure = false
    },{
      k = "ARM_TENANT_ID",
      v = data.azuread_client_config.this.tenant_id, secure = false
    },{
      k = "ARM_CLIENT_ID",
      v = azuread_application.serviceAccount1.application_id, secure = true
    },{
      k = "ARM_CLIENT_SECRET",
      v = azuread_application_password.serviceAccount1.value, secure = true
    },{
      k = "INFRA_IMMUTABLE_ID",
      v = random_id.repo_uniqid.hex, secure = false
    }]
}

