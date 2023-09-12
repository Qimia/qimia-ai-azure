resource "random_id" "resource_suffix" {
  byte_length = 2
}

data "azuread_group" "developers" {
  display_name = "qimia_ai_dev"
}