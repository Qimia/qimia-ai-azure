locals {
  app_config_map = {
    admin_email_address  = azurerm_key_vault_secret.admin-email-address.name
    admin_email_password = azurerm_key_vault_secret.admin-email-password.name
    email_password       = azurerm_key_vault_secret.email-password.name
    email_sender         = azurerm_key_vault_secret.email-address.name
    smtp_address         = azurerm_key_vault_secret.email-smtp.name
    db_password          = azurerm_key_vault_secret.db_password.name
    db_user              = azurerm_key_vault_secret.db_username.name
    db_host              = azurerm_key_vault_secret.db_url.name
    app_host             = azurerm_key_vault_secret.api_host.name
    frontend_host        = azurerm_key_vault_secret.frontend_host.name
    token                = azurerm_key_vault_secret.email-password.name
  }
  app_config_lines = concat(
    ["[app_config]"],
    [for k in keys(local.app_config_map) : "app_config_${k}_secret = \"${lookup(local.app_config_map, k)}\""],
    [
      "app_config_deployment_mode = \"azure\"",
      "app_config_llama_host = \"tcp://model:5555\"",
      "app_config_azure_key_vault_name = \"${azurerm_key_vault.app_secrets.name}\""
    ]
  )
  app_config_file = join("\n", local.app_config_lines)
}

resource "random_id" "app_config_prefix" {
  byte_length = 4
}

resource "azurerm_storage_blob" "app_config" {
  name                   = "${random_id.app_config_prefix.hex}_app_config.env"
  storage_account_name   = azurerm_storage_container.devops.storage_account_name
  storage_container_name = azurerm_storage_container.devops.name
  type                   = "Block"
  source_content         = local.app_config_file
}