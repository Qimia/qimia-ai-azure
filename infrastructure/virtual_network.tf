resource "azurerm_virtual_network" "this" {
  name                = "qimia-ai"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = var.env
  }
}

resource "azurerm_subnet" "public_subnets" {
  address_prefixes     = var.public_subnets
  name                 = "public"
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_subnet" "private_subnets" {
  address_prefixes     = var.private_subnets
  name                 = "private"
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
}