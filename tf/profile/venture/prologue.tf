terraform {
  required_providers {    
    azurerm = {
      configuration_aliases = [ azurerm.infrasupport ]
    }
    bitbucket = {
      source = "DrFaust92/bitbucket"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
} 

module "conf" {
  source = "../../../../conf"
}

locals {
  confmap = module.conf.values
}

