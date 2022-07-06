variable "name" { default = {} }
variable "location" { default = {} }
variable "resource_group_name" {}
variable "address_space" { default = [] }
variable "dns_servers" {
  default = []
  nullable = false
}

variable "subnets" { default = {} }


resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])
}

