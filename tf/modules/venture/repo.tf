#
## Bitbucket repo
#

variable "repo_enabled" { default = false }

locals {
  reponame = var.subscription_name
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
    }]
}

#data "bitbucket_current_user" "curuser" {}
data "bitbucket_workspace" "workspace" {
  workspace = var.bb_workspace
}

resource "bitbucket_repository" "repo1" {
  count            = var.repo_enabled ? 1 : 0
  owner            = data.bitbucket_workspace.workspace.id
  name             = local.reponame
  description      = "Repository and pipeline to manage azure '${local.reponame}' resources"
  project_key      = var.bb_project_key
  is_private       = var.bb_is_private
  fork_policy      = var.bb_fork_policy
  pipelines_enabled = var.bb_pipelines_enabled

  provisioner "local-exec" {
    command = "${path.cwd}/initrepo -D ${path.cwd} -n ${local.reponame} -url ${self.clone_https}"
  }
}

resource "bitbucket_repository_variable" "repo1" {
  count      = var.repo_enabled ? length(local.repovars) : 0
  repository = bitbucket_repository.repo1[0].id
  key        = local.repovars[count.index].k
  value      = local.repovars[count.index].v
  secured    = local.repovars[count.index].secure
}
