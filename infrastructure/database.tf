locals {
  psql_server_name = "qimia-ai-${random_id.resource_suffix.hex}"
}
resource "azurerm_postgresql_flexible_server" "app" {
  name                = local.psql_server_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres_admin_password.result
  delegated_subnet_id    = azurerm_subnet.db_subnets.id
  private_dns_zone_id    = azurerm_private_dns_zone.pgsql.id

  # Cheapest of this price tier.
  # Basic tier isn't an option as it doesn't support private endpoint.
  sku_name   = "GP_Standard_D2ds_v4"
  version    = "12"
  storage_mb = 1024 * 32
  tags       = {}
  zone       = "1"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false
  depends_on                   = [azurerm_subnet.db_subnets]

}

resource "random_password" "postgres_admin_password" {
  length  = 32
  special = false
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "postgres-admin"
  value        = random_password.postgres_admin_password.result
  depends_on   = [azurerm_postgresql_flexible_server.app, random_password.postgres_admin_password]
}


#resource "azurerm_private_endpoint" "vm_to_db_endpoint" {
#  name                = "qimia-ai-vm-to-db-${random_id.resource_suffix.hex}"
#  location            = data.azurerm_resource_group.this.location
#  resource_group_name = data.azurerm_resource_group.this.name
#  subnet_id           = azurerm_subnet.private_subnets.id
#  depends_on = [azurerm_subnet.private_subnets]
#
#
#  private_service_connection {
#    name                           = "qimia-ai-vm-to-db"
#    private_connection_resource_id = azurerm_postgresql_flexible_server.app.id
#    is_manual_connection           = false
#    subresource_names              = ["postgresqlServer"] # This is a value defined by Azure
#    # See: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource
#  }
#}


output "resid" {
  value = azurerm_postgresql_flexible_server.app.id
}


resource "azurerm_subnet" "db_subnets" {
  address_prefixes     = var.db_subnets
  name                 = "database"
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
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
  source_port_range      = "5432"
  destination_port_range      = "5432"
  source_address_prefix = "VirtualNetwork"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_subnet_network_security_group_association" "db_subnet_network_rules" {
  network_security_group_id = azurerm_network_security_group.database_subnet.id
  subnet_id = azurerm_subnet.db_subnets.id
}

resource "azurerm_private_dns_zone" "pgsql" {
  name                = "${local.psql_server_name}-te.private.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgsql" {
  name                  = "${azurerm_postgresql_flexible_server.app.name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.pgsql.name
  virtual_network_id    = azurerm_virtual_network.this.id
  resource_group_name   = data.azurerm_resource_group.this.name
}

resource "azurerm_key_vault_secret" "db_url" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "postgres-host"
  value        = "${azurerm_postgresql_flexible_server.app.name}.postgres.database.azure.com:5432"
}

resource "azurerm_key_vault_secret" "db_password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "database-master-password"
  value        = azurerm_postgresql_flexible_server.app.administrator_password
}

resource "azurerm_key_vault_secret" "db_username" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "database-master-username"
  value        = azurerm_postgresql_flexible_server.app.administrator_login
}