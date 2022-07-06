variable "datafile" {}
variable "location" {}
variable "resource_group_name" {}


locals {
  conf = yamldecode(file(var.datafile))
  vnets = lookup(local.conf, "virtual_networks", {})
}

module "vnets" {
  source              = "./vnet"
  for_each            = local.vnets

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = lookup(each.value,"location",var.location)

  address_space       = each.value.address_space
  dns_servers         = lookup(each.value, "dns_servers", [])
  subnets             = lookup(each.value, "subnets", {})
}

