terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

variable "name" {}
variable "args" {}

resource "github_repository" "repo" {
  name             = try(var.args.name,var.name)
  description      = try(var.args.description,"Amnesiac")
  visibility       = try(var.args.visibility,null)
  has_projects     = try(var.args.has_projects,null)
  has_wiki         = try(var.args.has_wiki,null)
  auto_init        = try(var.args.auto_init,null)
  license_template = try(var.args.license_template,null)

  lifecycle {
    ignore_changes = [
      default_branch,
      topics,
      has_issues,
      has_wiki,
      has_downloads,
      has_projects,
      vulnerability_alerts
    ]
  }
}
