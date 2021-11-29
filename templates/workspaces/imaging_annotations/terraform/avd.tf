resource "time_rotating" "avdhp_token_expiry" {
  rotation_days = 27
}

resource "azurerm_virtual_desktop_host_pool" "avdhp" {
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name

  name                     = "avdhp-${local.workspace_resource_name_suffix}"
  friendly_name            = "avdhp-${local.workspace_resource_name_suffix}"
  validate_environment     = true
  custom_rdp_properties    = "targetisaadjoined:i:1;drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;use multimon:i:1;"
  description              = "AVD Host Pool for TRE workspace ${local.short_workspace_id}"
  type                     = "Pooled"
  maximum_sessions_allowed = 10
  load_balancer_type       = "BreadthFirst"

  registration_info {
    expiration_date = time_rotating.avdhp_token_expiry.rotation_rfc3339
  }
}

resource "azurerm_virtual_desktop_application_group" "avddag" {
  name                = "avddag-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avdhp.id
  description         = "AVD Application Group (Desktop) for TRE workspace ${local.short_workspace_id}"
}

resource "azurerm_virtual_desktop_workspace" "avdws" {
  name                = "avdws-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  description         = "AVD Workspace for TRE workspace ${local.short_workspace_id}"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspaceremoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.avdws.id
  application_group_id = azurerm_virtual_desktop_application_group.avddag.id
}

resource "random_password" "avdhost_adminuser_password" {
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

resource "azurerm_key_vault_secret" "avdhost_adminuser_password" {
  name         = "avdhost-adminuser-password"
  value        = random_password.avdhost_adminuser_password.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.kvp_terraform]
}

resource "azurerm_network_interface" "avdhost_nic" {
  name                = "avdhost-nic-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.services.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "avdhost" {
  name                = "avdhost-${local.short_workspace_id}"
  resource_group_name = azurerm_resource_group.ws.name
  location            = azurerm_resource_group.ws.location
  size                = "Standard_NV4as_v4"
  admin_username      = "adminuser"
  admin_password      = random_password.avdhost_adminuser_password.result
  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [
    azurerm_network_interface.avdhost_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "azureadjoin" {
  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.avdhost.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"
}

resource "azurerm_virtual_machine_extension" "winamdgpudrivers" {
  name                 = "AmdGpuDriverWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.avdhost.id
  publisher            = "Microsoft.HpcCompute"
  type                 = "AmdGpuDriverWindows"
  type_handler_version = "1.0"
}

resource "azurerm_virtual_machine_extension" "avdhpjoin" {
  name                       = "avdhost_extension_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avdhost.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${azurerm_virtual_desktop_host_pool.avdhp.name}",
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool.avdhp.registration_info[0].token}"
      }
    }
  SETTINGS

  depends_on = [azurerm_virtual_machine_extension.azureadjoin, azurerm_virtual_machine_extension.winamdgpudrivers]
}

