resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]

  tags = {
    environment = var.env
  }
  count = var.create_vnet
}

data "azurerm_virtual_network" "virtual_network" {
  depends_on          = [azurerm_virtual_network.this]
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

module "subnets" {
  source              = "./subnets"
  vnet_name           = var.vnet_name
  vnet_cidr           = var.vnet_cidr
  resource_group_name = var.resource_group_name
  db_subnet           = var.db_subnet
  db_subnet_name      = var.db_subnet_name
  public_subnet       = var.public_subnet
  public_subnet_name  = var.public_subnet_name
  private_subnet      = var.private_subnet
  private_subnet_name = var.private_subnet_name
  depends_on          = [azurerm_virtual_network.this]
  count               = var.create_subnet
}


data "azurerm_subnet" "private" {
  depends_on           = [module.subnets]
  name                 = var.private_subnet_name
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}

data "azurerm_subnet" "public" {
  depends_on           = [module.subnets]
  name                 = var.public_subnet_name
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}
data "azurerm_subnet" "database" {
  depends_on           = [module.subnets]
  name                 = var.db_subnet_name
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}