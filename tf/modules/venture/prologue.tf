terraform {
  required_providers {    
    azurerm = {
      configuration_aliases = [ azurerm.infrasupport ]
    }
    bitbucket = {
      source = "DrFaust92/bitbucket"
    }
  }
} 

module "conf" {
  source = "../../../../conf"
}

locals {
  confmap = module.conf.values
}

