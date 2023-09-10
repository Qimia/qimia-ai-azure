resource "azurerm_lb" "this" {
  name                = "qimia-ai-${random_id.resource_suffix.hex}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }
  sku = "Standard"
}

resource "azurerm_public_ip" "lb_ip" {
  name="qimiaAiDev${random_id.resource_suffix.hex}"
  location = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method = "Static"
  sku = "Standard"

}

resource "azurerm_lb_rule" "frontend" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "FrontendHttpForward"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.vm_ips.id]
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_rule" "ssh_conn" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "FrontendSSHForward"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.vm_ips.id]
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_backend_address_pool" "vm_ips" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "VM_IPs"
}

resource "azurerm_network_interface" "frontend-nic" {
  name                = "frontend-nic"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "frontend_config"
    subnet_id                     = azurerm_subnet.private_subnets.id
    private_ip_address_allocation = "Dynamic"
  }
}
