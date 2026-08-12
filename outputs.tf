output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "Storage Account Name"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_id" {
  description = "Storage Account Resource ID"
  value       = azurerm_storage_account.storage.id
}

output "storage_location" {
  value = azurerm_storage_account.storage.location
}

output "vm_public_ip" {
  description = "Public IP address of the Linux VM"
  value       = azurerm_public_ip.vm_pip.ip_address
}