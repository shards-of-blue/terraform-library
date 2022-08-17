terraform {
 required_providers {
    bitbucket = {
      source = "DrFaust92/bitbucket"
      version = "2.20.0"
    }
  }

  required_version = ">= 1.1.0"

}

variable "name" {}
variable "args" {}

data "bitbucket_workspace" "workspace" {
  workspace = var.args.workspace
}

resource "bitbucket_repository" "repo" {
  owner             = data.bitbucket_workspace.workspace.id
  name              = try(var.args.name,var.name)
  description       = try(var.args.description,"Amnesiac")
  project_key       = try(var.args.project_key,null)
  is_private        = try(var.args.is_private,true)
  fork_policy       = try(var.args.fork_policy,"no_forks")
  pipelines_enabled = true
}
