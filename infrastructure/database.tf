locals {
  psql_server_name = "qimia-ai-${random_id.resource_suffix.hex}"
}
resource "azurerm_postgresql_flexible_server" "app" {
  name                = local.psql_server_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres_admin_password.result
  delegated_subnet_id    = data.azurerm_subnet.database.id
  private_dns_zone_id    = azurerm_private_dns_zone.pgsql.id

  # Cheapest of this price tier.
  # Basic tier isn't an option as it doesn't support private endpoint.
  sku_name   = "GP_Standard_D2ds_v4"
  version    = "14"
  storage_mb = 1024 * 32
  tags       = {}
  zone       = "1"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false
  depends_on                   = [data.azurerm_subnet.database]

}

resource "azurerm_postgresql_flexible_server_database" "app_db" {
  name      = "test_db"
  server_id = azurerm_postgresql_flexible_server.app.id
}

resource "azurerm_postgresql_flexible_server_configuration" "db_extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.app.id
  value     = "uuid-ossp"
}

resource "random_password" "postgres_admin_password" {
  length  = 32
  special = false
}


resource "azurerm_private_dns_zone" "pgsql" {
  name                = "${local.psql_server_name}-te.private.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgsql" {
  name                  = "${azurerm_postgresql_flexible_server.app.name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.pgsql.name
  virtual_network_id    = data.azurerm_virtual_network.virtual_network.id
  resource_group_name   = data.azurerm_resource_group.this.name
}

resource "azurerm_key_vault_secret" "db_url" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "database-host"
  content_type = "The hostname for the Postgres flexible server ${azurerm_postgresql_flexible_server.app.name}"
  value        = "${azurerm_postgresql_flexible_server.app.name}.postgres.database.azure.com:5432"
}

resource "azurerm_key_vault_secret" "db_password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "database-password"
  content_type = "User password for the Postgres flexible server ${azurerm_postgresql_flexible_server.app.name} user ${azurerm_key_vault_secret.db_username.value}."
  value        = azurerm_postgresql_flexible_server.app.administrator_password
}

resource "azurerm_key_vault_secret" "db_username" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "database-username"
  content_type = "Username for the Postgres flexible server ${azurerm_postgresql_flexible_server.app.name}."
  value        = azurerm_postgresql_flexible_server.app.administrator_login
}