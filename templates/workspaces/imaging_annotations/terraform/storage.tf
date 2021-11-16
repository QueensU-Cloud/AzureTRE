resource "azurerm_storage_account" "stg" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.ws.name
  location                 = azurerm_resource_group.ws.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
  nfsv3_enabled            = true
  enable_https_traffic_only = false

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.services.id]
    bypass                     = ["AzureServices"]
  }

  lifecycle { ignore_changes = [tags] }
}

resource "azurerm_role_assignment" "rp-createstoragecontainer" {
  scope                = azurerm_storage_account.stg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.rp-msi.principal_id
}

# resource "azurerm_storage_data_lake_gen2_filesystem" "monai_data" {
#   name               = "monai-data"
#   storage_account_id = azurerm_storage_account.stg.id

#   ace {
#     scope = "default"
#     type = "other"
#     permissions = "r--"
#   }
# }





resource "azurerm_private_endpoint" "stgfilepe" {
  name                = "stgfilepe-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  subnet_id           = azurerm_subnet.services.id

  lifecycle { ignore_changes = [tags] }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.filecore.id]
  }

  private_service_connection {
    name                           = "stgfilepesc-${local.workspace_resource_name_suffix}"
    private_connection_resource_id = azurerm_storage_account.stg.id
    is_manual_connection           = false
    subresource_names              = ["File"]
  }
}


resource "azurerm_private_endpoint" "stgblobpe" {
  name                = "stgblobpe-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  subnet_id           = azurerm_subnet.services.id

  lifecycle { ignore_changes = [tags] }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blobcore.id]
  }

  private_service_connection {
    name                           = "stgblobpesc-${local.workspace_resource_name_suffix}"
    private_connection_resource_id = azurerm_storage_account.stg.id
    is_manual_connection           = false
    subresource_names              = ["Blob"]
  }
}
