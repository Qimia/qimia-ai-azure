resource "azurerm_log_analytics_workspace" logs {
  location = data.azurerm_resource_group.this.location
  name = "applogs"
  resource_group_name = data.azurerm_resource_group.this.name
}
#
#resource "azurerm_role_assignment" "vm_logs" {
#  principal_id = azurerm_user_assigned_identity.vm.principal_id
#  scope        = azurerm_log_analytics_workspace.logs.id
#  role_definition_name = ""
#}


resource "azurerm_virtual_machine_scale_set_extension" "vm_logs" {
  name                         = "vm_logs"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "1.27"
  settings = jsonencode(
    {
      "authentication" = {
        "managedIdentity" = {
          "identifier-name" = "mi_res_id"
          "identifier-value" = azurerm_user_assigned_identity.vm.id
        }
      }
    }
  )
}