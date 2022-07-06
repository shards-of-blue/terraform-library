#
## Manage databases and server settings defined in input file (yaml format)
#

locals {
  db_data            = yamldecode(file(var.db_data))

  server_parameters = lookup(local.db_data, "server_parameters", {})
  dbs               = lookup(local.db_data, "databases", {})
}

## Generate a db server admin password (that optionally also goes in a key vault)
resource "random_password" "db_admin_password" {
  length           = var.password_length
  special          = false
  #override_special = ":"
}

#
## Configure mariadb service resource
## cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mariadb_database
#
resource "azurerm_mariadb_server" "mysqlService1" {
  name                          = var.db_servicename
  location                      = var.location
  resource_group_name           = var.resource_group_name

  administrator_login           = var.admin_account
  administrator_login_password  = random_password.db_admin_password.result

  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  version                       = var.db_version

  auto_grow_enabled             = var.auto_grow_enabled
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  public_network_access_enabled = var.public_network_access_enabled
  ssl_enforcement_enabled       = var.ssl_enforcement_enabled
}

## Store password in keyvault, if requested
resource "azurerm_key_vault_secret" "store-dbserver-password" {
  count         = (var.key_vault_id != "") ? 1 : 0
  name          = "${var.db_servicename}-dbserver-accesskey"
  value         = random_password.db_admin_password.result
  key_vault_id  = var.key_vault_id
  #depends_on   = [azurerm_key_vault_access_policy.deployAccountAccess1]
}

## Manage db server parameters
resource "azurerm_mariadb_configuration" "server_parameters" {
  for_each            = local.server_parameters
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mariadb_server.mysqlService1.name
  name                = each.key
  value               = each.value
}

## Configure databases on this service
resource "azurerm_mariadb_database" "databases" {
  for_each            = local.dbs
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mariadb_server.mysqlService1.name
  charset             = lookup(each.value, "charset", "utf8")
  collation           = lookup(each.value, "collation", "utf8_general_ci")
}
