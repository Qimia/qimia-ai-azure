locals {
  admin_username = "ai_admin"
}
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmscaleset"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  automatic_os_upgrade_policy {
    disable_automatic_rollback  = false
    enable_automatic_os_upgrade = false
  }
  upgrade_mode = "Automatic"

  sku       = var.machine_sku
  instances = 2

  computer_name_prefix = "qimiaai"
  admin_username       = local.admin_username
  admin_password       = random_password.vm_admin_password.result

  admin_ssh_key {
    public_key = file("../qimia-ai.pub")
    username   = local.admin_username
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

  network_interface {
    name    = "main"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.public_subnets.id

#      load_balancer_backend_address_pool_ids
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vm_ips.id]
#      public_ip_address { ## TODO experiment only, remove when going to production
#        name = "temp_public_ip"
#      }
    }
    network_security_group_id = azurerm_network_security_group.vm.id
  }

  disable_password_authentication = false
  tags = {
    env = var.env
  }
  depends_on = [azurerm_subnet.private_subnets, azurerm_network_security_group.vm, azurerm_user_assigned_identity.vm]
}

resource "random_password" "vm_admin_password" {
  length  = 32
  special = false
}

resource "azurerm_virtual_machine_scale_set_extension" "vm_starter" {
  name                         = "starter"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"
  settings = jsonencode({
    "commandToExecute" = join(
      "; ",
      [
        "set -e",
        "whoami >> /home/ai_admin/init_user.txt",
        "apt update",
        "apt install -y docker.io docker-compose azure-cli postgresql-client-common postgresql-client-12",
        "docker run --rm -d -it -p 80:80 yeasy/simple-web:latest"
      ]
    )
  })
}

resource "azurerm_network_security_group" "vm" {
  name                = "vm_security_group_${random_id.resource_suffix.hex}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "vm_inbound_rule" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_ssh"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 1000
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.vm.resource_group_name
  depends_on                  = [azurerm_network_security_group.vm]
}
resource "azurerm_network_security_rule" "vm_outbound_rule" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allow_ssh_out"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 1000
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.vm.resource_group_name
  depends_on                  = [azurerm_network_security_group.vm]
}

resource "azurerm_subnet_network_security_group_association" "subnet_network_rules" {
  network_security_group_id = azurerm_network_security_group.vm.id
  subnet_id = azurerm_subnet.public_subnets.id
}


resource "azurerm_user_assigned_identity" "vm" {
  location            = data.azurerm_resource_group.this.location
  name                = "app_${random_id.resource_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" vm {
  principal_id = azurerm_user_assigned_identity.vm.principal_id
  scope = data.azurerm_resource_group.this.id
  role_definition_name = "Reader"
}