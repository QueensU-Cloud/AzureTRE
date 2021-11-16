resource "random_password" "monai_vm_adminuser_password" {
  length           = 16
  special          = true
  min_special = 1
  override_special = "_%@"
  upper = true
  min_upper = 1
  lower = true
  min_lower = 1
  number = true
  min_numeric = 1
}

resource "azurerm_key_vault_secret" "monai_vm_adminuser_password" {
  name         = "monai-vm-adminuser-password"
  value        = random_password.monai_vm_adminuser_password.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.kvp_terraform]
}

resource "azurerm_network_interface" "monai_nic" {
  name                = "nic-monailabel-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.services.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "monai_vm" {
  name                = "vm-monailabel-${local.workspace_resource_name_suffix}"
  resource_group_name = azurerm_resource_group.ws.name
  location            = azurerm_resource_group.ws.location
  size                = "Standard_NC6s_v3" #NVIDIA
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.monai_nic.id,
  ]

  admin_password = random_password.monai_vm_adminuser_password.result
  disable_password_authentication = false
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "ubuntu-1804"
    sku       = "1804-gen2"
    version   = "latest"
  }
  allow_extension_operations = true
}
