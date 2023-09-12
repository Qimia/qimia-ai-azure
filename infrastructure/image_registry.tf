resource "azurerm_container_registry" "app" {
  location            = data.azurerm_resource_group.this.location
  name                = "qimiaai${random_id.resource_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Standard"
}