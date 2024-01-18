resource "azurerm_container_registry" "app" {
  location            = data.azurerm_resource_group.this.location
  name                = "qimiaai${random_id.resource_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Standard"
}
resource "azurerm_role_assignment" "azurerm_container_registry_app_reader" {
  count = var.use_dockerhub ? 0 : 1
  principal_id = azurerm_user_assigned_identity.vm.id
  scope        = azurerm_container_registry.app.id
  role_definition_name = "Reader"
}

resource "azurerm_role_assignment" "azurerm_container_registry_app_acrpull" {
  count = var.use_dockerhub ? 0 : 1
  principal_id = azurerm_user_assigned_identity.vm.id
  scope        = azurerm_container_registry.app.id
  role_definition_name = "AcrPull"
}