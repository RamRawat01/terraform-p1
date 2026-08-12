variable "location" {
  description = "Azure Region"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
  default     = "myTFResourceGroup"
}

variable "storage_account_name" {
  description = "Storage Account Name"
  type        = string
}