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
  name                = "qimiaAiDev${random_id.resource_suffix.hex}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "qimia-ai-${random_id.resource_suffix.hex}"
}

resource "azurerm_key_vault_secret" "api_host" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "api-host"
  content_type = "The DNS of the backend api optionally including the port."
  value        = "${azurerm_public_ip.lb_ip.fqdn}:${local.api_port}"
}

resource "azurerm_key_vault_secret" "frontend_host" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name         = "frontend-host"
  content_type = "The DNS of the backend api optionally including the port."
  value        = "${azurerm_public_ip.lb_ip.fqdn}:80"
}

resource "azurerm_lb_rule" "frontend" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "FrontendHttpForward"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 3000
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vm_ips.id]
  frontend_ip_configuration_name = "PublicIPAddress"
}
resource "azurerm_lb_rule" "webapi" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "WebApiHttpForward"
  protocol                       = "Tcp"
  frontend_port                  = local.api_port
  backend_port                   = 8000 # The port exposed from the web API container
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vm_ips.id]
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_rule" "ssh_conn" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "FrontendSSHForward"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vm_ips.id]
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
    subnet_id                     = data.azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

locals {
  backend_http_protocol = var.custom_backend_dns == "" ? "http" : "https"
  frontend_http_protocol = var.custom_frontend_dns == "" ? "http" : "https"

  backend_dns = var.custom_backend_dns == "" ? "${azurerm_public_ip.lb_ip.fqdn}:8000" : var.custom_backend_dns
  frontend_dns = var.custom_frontend_dns == "" ? "${azurerm_public_ip.lb_ip.fqdn}:80" : var.custom_frontend_dns

  backend_url = "${local.backend_http_protocol}://${local.backend_dns}"
  frontend_url = "${local.frontend_http_protocol}://${local.frontend_dns}"
}

output frontend_url {
  value = local.frontend_url
}

output backend_url {
  value = local.backend_url
}