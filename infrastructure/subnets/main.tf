data azurerm_resource_group this {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "this" {
  name = var.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "public_subnets" {
  address_prefixes     = [var.public_subnet]
  name                 = var.public_subnet_name
  resource_group_name  = data.azurerm_virtual_network.this.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

resource "azurerm_subnet" "private_subnets" {
  address_prefixes     = [var.private_subnet]
  name                 = var.private_subnet_name
  resource_group_name  = data.azurerm_virtual_network.this.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.this.name
}



resource "azurerm_subnet" "db_subnets" {
  address_prefixes     = [var.db_subnet]
  name                 = var.db_subnet_name
  resource_group_name  = data.azurerm_virtual_network.this.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.this.name
  delegation {
    name = "delegate_to_postgresql"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  service_endpoints = [
    "Microsoft.Storage"
  ]
}

resource "azurerm_network_security_group" "database_subnet" {
  location            = data.azurerm_resource_group.this.location
  name                = "db_network"
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "allow_db_5432" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_5432_from_private_subnet"
  network_security_group_name = azurerm_network_security_group.database_subnet.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = data.azurerm_resource_group.this.name
  source_port_range           = "5432"
  destination_port_range      = "5432"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
}

resource "azurerm_subnet_network_security_group_association" "db_subnet_network_rules" {
  network_security_group_id = azurerm_network_security_group.database_subnet.id
  subnet_id                 = azurerm_subnet.db_subnets.id
}