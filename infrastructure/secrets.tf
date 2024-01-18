resource "azurerm_key_vault_secret" "email-password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "email-password"
  value        = ""
  content_type = "The email address password to the address defined in the secret 'email-address'."
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    "file-encoding": "utf-8"
  }
}

resource "azurerm_key_vault_secret" "email-smtp" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "email-smtp"
  value        = ""
  content_type = "The smtp email send address for the email address defined in the secret 'email-address'."
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    "file-encoding": "utf-8"
  }
}

resource "azurerm_key_vault_secret" "email-address" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "email-address"
  value        = ""
  content_type = "The email address to communicate to the  users regarding activation and email resets etc."
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    "file-encoding": "utf-8"
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
  content_type = "Initial Admin user's email password."
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    "file-encoding": "utf-8"
  }
}
resource "azurerm_key_vault_secret" "admin-email-address" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "admin-email-address"
  value        = ""
  content_type = "Initial Admin user's email address."
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    "file-encoding": "utf-8"
  }
}