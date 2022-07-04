#
## Bitbucket repo
#

## generate a unique id for resources that may require this
resource "random_id" "repo_uniqid" {
  byte_length = 8
}

locals {
  reponame = var.name

  ## make a map of default values from global configuration items
  repo_defaults = {
    project_key = local.confmap.bb_default_project_key
    is_private = local.confmap.bb_default_is_private
    fork_policy = local.confmap.bb_default_fork_policy
    workspace = local.confmap.bb_default_workspace
    pipelines_enabled = local.confmap.bb_default_pipelines_enabled
    repo_enabled = local.confmap.bb_default_repo_enabled
  }

  ## merge defaults with the parameters that were passed in
  mrepoargs = merge(local.repo_defaults, var.args)

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

#data "bitbucket_current_user" "curuser" {}
data "bitbucket_workspace" "workspace" {
  workspace = local.mrepoargs.workspace
}

resource "bitbucket_repository" "repo1" {
  count            = local.mrepoargs.repo_enabled ? 1 : 0
  owner            = data.bitbucket_workspace.workspace.id
  name             = local.reponame
  description      = "Repository and pipeline to manage azure '${local.reponame}' resources"
  project_key      = local.mrepoargs.project_key
  is_private       = local.mrepoargs.is_private
  fork_policy      = local.mrepoargs.fork_policy
  pipelines_enabled = local.mrepoargs.pipelines_enabled

  provisioner "local-exec" {
    command = "${path.cwd}/initrepo -D ${path.cwd} -n ${local.reponame} -url ${self.clone_https} -iid ${random_id.repo_uniqid.hex}"
  }
  lifecycle {
    ## attributes that should not be reverted to module defaults
    ignore_changes = [
      website,
      has_issues,
      has_wiki,
      link
    ]
  }
}

resource "bitbucket_repository_variable" "repo1" {
  count      = local.mrepoargs.repo_enabled ? length(local.repovars) : 0
  repository = bitbucket_repository.repo1[0].id
  key        = local.repovars[count.index].k
  value      = local.repovars[count.index].v
  secured    = local.repovars[count.index].secure
}
