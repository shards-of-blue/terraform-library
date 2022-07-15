#
## Bitbucket repo
#

locals {
  ## make a map of default values from global configuration items
  bb_repo_defaults = {
    repo_enabled = local.confmap.bitbucket.default_repo_enabled
    project_key = local.confmap.bitbucket.default_project_key
    is_private = local.confmap.bitbucket.default_is_private
    fork_policy = local.confmap.bitbucket.default_fork_policy
    workspace = local.confmap.bitbucket.default_workspace
    pipelines_enabled = local.confmap.bitbucket.default_pipelines_enabled
  }

  ## merge defaults with the parameters that were passed in
  bb_repoargs = merge(local.bb_repo_defaults, var.args)

}

## find our bitbucket workspace id
data "bitbucket_workspace" "workspace" {
  count     = local.bb_repoargs.repo_enabled ? 1 : 0
  workspace = local.bb_repoargs.workspace
}

resource "bitbucket_repository" "repo1" {
  count            = local.bb_repoargs.repo_enabled ? 1 : 0
  owner            = data.bitbucket_workspace.workspace[0].id
  name             = local.reponame
  description      = "Repository and pipeline to manage azure '${local.reponame}' resources"
  project_key      = local.bb_repoargs.project_key
  is_private       = local.bb_repoargs.is_private
  fork_policy      = local.bb_repoargs.fork_policy
  pipelines_enabled = local.bb_repoargs.pipelines_enabled

  provisioner "local-exec" {
    command = "${path.cwd}/initrepo -T bitbucket -D ${path.cwd} -n ${local.reponame} -url ${self.clone_https} -iid ${random_id.repo_uniqid.hex}"
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

## add repo variables
resource "bitbucket_repository_variable" "repo1" {
  count      = local.bb_repoargs.repo_enabled ? length(local.repovars) : 0
  repository = bitbucket_repository.repo1[0].id
  key        = local.repovars[count.index].k
  value      = local.repovars[count.index].v
  secured    = local.repovars[count.index].secure
}
