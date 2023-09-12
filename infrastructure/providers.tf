terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.72.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.41.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}