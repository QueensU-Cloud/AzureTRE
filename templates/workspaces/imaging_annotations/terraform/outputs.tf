output "workspace_resource_name_suffix" {
  value = local.workspace_resource_name_suffix
}

output "monai_vm_name" {
  value = azurerm_linux_virtual_machine.monai_vm.name
}

output "avd_vm_name" {
  value = azurerm_windows_virtual_machine.avdhost.name
}

output "rg_name" {
  value = azurerm_resource_group.ws.name
}

output "blob_dns_zone" {
  value = data.azurerm_private_dns_zone.blobcore.name
}

output "storage_account_name" {
  value = azurerm_storage_account.stg.name
}
