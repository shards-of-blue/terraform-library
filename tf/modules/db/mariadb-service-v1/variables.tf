variable "db_servicename"      {}
variable "location"            {}
variable "resource_group_name" {}
variable "db_data"             {}
variable "key_vault_id"        { default = null }
variable "key_vault_key_id"    { default = null }
variable "password_length"     { default = 16 }

variable "sku_name"   { default = "B_Gen5_2" }
variable "storage_mb" { default = 5120 }
variable "db_version" { default = "10.3" }

variable "auto_grow_enabled"             { default  = true }
variable "backup_retention_days"         { default  = 7 }
variable "geo_redundant_backup_enabled"  { default  = false }
variable "public_network_access_enabled" { default = true }
variable "ssl_enforcement_enabled"       { default  = true }
variable "admin_account"                 { default = "qabbala" }
