resource "azurerm_key_vault" "app_secrets" {
  location                  = data.azurerm_resource_group.this.location
  name                      = "app-secret-${random_id.resource_suffix.hex}"
  resource_group_name       = data.azurerm_resource_group.this.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = var.rbac_keyvault
}

# Grant VMs read access to secrets
# Created in case of Keyvault RBAC authentication
resource "azurerm_role_assignment" "vm_keyvault_secrets_reader" {
  count = var.rbac_keyvault ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
  scope                = azurerm_key_vault.app_secrets.id
  role_definition_name = "Key Vault Secrets User"
}

# Created in case of Keyvault non-RBAC authentication, grant the SP read/write access to Keyvault
resource "azurerm_key_vault_access_policy" "sp_keyvault_secrets_writer" {
  count = var.rbac_keyvault ? 0 : 1
  key_vault_id = azurerm_key_vault.app_secrets.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
  ]
}

resource "azurerm_key_vault_access_policy" "vm_keyvault_secrets_reader" {
  count = var.rbac_keyvault ? 0 : 1
  key_vault_id = azurerm_key_vault.app_secrets.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.vm.principal_id
  secret_permissions = [
    "Get",
    "List",
  ]
}

output "key_vault_name" {
  value = azurerm_key_vault.app_secrets.name
}