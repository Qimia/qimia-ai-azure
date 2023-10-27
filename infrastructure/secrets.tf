resource "azurerm_key_vault_secret" "email-password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "email-password"
  value        = ""
  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "email-smtp" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "email-smtp"
  value        = ""
  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "email-address" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "email-address"
  value        = ""
  lifecycle {
    ignore_changes = [value]
  }
}

resource random_password admin_initial_web_app_password {
  length = 32
  special = false
}

resource "azurerm_key_vault_secret" "admin-email-password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "admin-email-password"
  value        = random_password.admin_initial_web_app_password.result
  lifecycle {
    ignore_changes = [value]
  }
}
resource "azurerm_key_vault_secret" "admin-email-address" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "admin-email-address"
  value        = ""
  lifecycle {
    ignore_changes = [value]
  }
}