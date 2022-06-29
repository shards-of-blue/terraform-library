variable "subscription_name" {}
variable "location" { default = "westeurope" }
variable "billing_account_name" {}
variable "enrollment_account_name" {}
variable "subscription_workload" { default = "DevTest" }
variable "mg_association" { default = "" }
variable "infra_provisioning_storage_account" {}
variable "infra_provisioning_resource_group" {}

variable "bb_workspace" {}
variable "bb_project_key" {}
variable "bb_is_private"  {}
variable "bb_fork_policy" {}
variable "bb_pipelines_enabled" {}

