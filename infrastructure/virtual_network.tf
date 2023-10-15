resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]

  tags = {
    environment = var.env
  }
}

resource "azurerm_subnet" "public_subnets" {
  address_prefixes     = [var.public_subnet]
  name                 = var.public_subnet_name
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_subnet" "private_subnets" {
  address_prefixes     = [var.private_subnet]
  name                 = var.private_subnet_name
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
}