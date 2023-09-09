resource "azurerm_key_vault" "app_secrets" {
  location            = data.azurerm_resource_group.this.location
  name                = "app-secrets-${random_id.resource_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # TODO temporary. Grants access to whoever is deploying the stack
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create"
    ]
    secret_permissions = [
      "Get",
      "List",
      "Set"
    ]
  }
}