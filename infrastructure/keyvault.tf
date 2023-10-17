resource "azurerm_key_vault" "app_secrets" {
  location                  = data.azurerm_resource_group.this.location
  name                      = "app-secrets-${random_id.resource_suffix.hex}"
  resource_group_name       = data.azurerm_resource_group.this.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true
}

# Grant VMs read access to secrets
resource "azurerm_role_assignment" "vm_keyvault_secrets_reader" {
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
  scope                = azurerm_key_vault.app_secrets.id
  role_definition_name = "Key Vault Secrets User"
}

output "key_vault_name" {
  value = azurerm_key_vault.app_secrets.name
}