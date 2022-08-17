terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
    }
  }
}

variable "name" {}
variable "args" {}

data "azuredevops_project" "pr1" {
  name = var.args.projectname
}

resource "azuredevops_git_repository" "repo1" {
  project_id     = data.azuredevops_project.pr1.id
  name           = try(var.args.name, var.name)
  default_branch = try(var.args.default_branch, "refs/heads/main")

  initialization {
    init_type = try(var.args.init_type, "Clean")
  }

  lifecycle {
    ignore_changes = [
    ]
  }
}
