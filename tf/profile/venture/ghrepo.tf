#
## github repo
#

locals {
  ## make a map of default values from global configuration items
  gh_repo_defaults = {
    repo_enabled = local.confmap.github.default_repo_enabled
    visibility   = local.confmap.github.default_visibility
    has_projects = local.confmap.github.default_has_projects
    has_wiki     = local.confmap.github.default_has_wiki
    license_template = local.confmap.github.default_license_template
  }

  ## merge defaults with the parameters that were passed in
  gh_repoargs = merge(local.gh_repo_defaults, try(var.args.github,{}))
}

resource "github_repository" "repo1" {
  count            = local.gh_repoargs.repo_enabled ? 1 : 0
  name             = local.reponame
  description      = "Repository and pipeline to manage azure '${local.reponame}' resources"
  visibility       = local.gh_repoargs.visibility
  has_projects     = local.gh_repoargs.has_projects
  has_wiki         = local.gh_repoargs.has_wiki
  auto_init        = false
  license_template = local.gh_repoargs.license_template

  provisioner "local-exec" {
    command = "${path.cwd}/initrepo -T github -D ${path.cwd} -n ${local.reponame} -url ${self.http_clone_url} -iid ${random_id.repo_uniqid.hex}"
  }
  lifecycle {
    ## attributes that should not be reverted to module defaults
    ignore_changes = [
      has_issues,
      has_wiki
    ]
  }
}

## add repo variables
resource "github_actions_secret" "repo1" {
  count           = local.gh_repoargs.repo_enabled ? length(local.repovars) : 0
  repository      = github_repository.repo1[0].name
  secret_name     = local.repovars[count.index].k
  plaintext_value = local.repovars[count.index].v
}
