terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "infrastructure.tfstate"
  }
}