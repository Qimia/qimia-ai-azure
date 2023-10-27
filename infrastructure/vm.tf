locals {
  admin_username = "ai_admin"
  api_port       = 8000
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
  instances = 1

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
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

  network_interface {
    name    = "main"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = data.azurerm_subnet.public.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vm_ips.id]
    }
    network_security_group_id = azurerm_network_security_group.vm.id
  }

  disable_password_authentication = false
  encryption_at_host_enabled      = true
  tags = {
    env = var.env
  }
  depends_on = [data.azurerm_subnet.private, azurerm_network_security_group.vm, azurerm_user_assigned_identity.vm]
}

resource "random_password" "vm_admin_password" {
  length  = 32
  special = false
}

resource "azurerm_storage_blob" "bootstrap_script" {
  name                   = "bootstrap.sh"
  storage_account_name   = azurerm_storage_container.devops.storage_account_name
  storage_container_name = azurerm_storage_container.devops.name
  type                   = "Block"
  source                 = "bootstrap.sh"
  content_md5            = filemd5("bootstrap.sh")
}

resource "azurerm_storage_blob" "sync_logs_script" {
  name                   = "sync-logs.sh"
  storage_account_name   = azurerm_storage_container.devops.storage_account_name
  storage_container_name = azurerm_storage_container.devops.name
  type                   = "Block"
  source                 = "sync-logs.sh"
  content_md5            = filemd5("sync-logs.sh")
}


resource "azurerm_virtual_machine_scale_set_extension" "vm_starter" {
  name                         = "starter"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"

  settings = jsonencode({
    "commandToExecute" = join("; ", [
      "set -e",
      "echo ${azurerm_storage_blob.bootstrap_script.content_md5}",
      "echo ${azurerm_storage_blob.sync_logs_script.content_md5}",
      "echo ${azurerm_storage_blob.docker_compose_file.content_md5}",
      "sh bootstrap.sh",
      "sh sync-logs.sh \"${azurerm_storage_container.logs.storage_account_name}\" \"${azurerm_storage_container.logs.name}\" & ",
      ]
    )
  })
  protected_settings = jsonencode({
    "storageAccountName" = azurerm_storage_blob.sync_logs_script.storage_account_name,
    "storageAccountKey"  = azurerm_storage_account.vm_storage.primary_access_key,
    "fileUris" = [
      azurerm_storage_blob.bootstrap_script.url,
      azurerm_storage_blob.sync_logs_script.url,
      azurerm_storage_blob.docker_compose_file.url
    ]
  })
  depends_on = [azurerm_storage_blob.bootstrap_script, azurerm_storage_blob.sync_logs_script]
}


resource "azurerm_network_security_group" "vm" {
  name                = "vm_security_group_${random_id.resource_suffix.hex}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "inbound_http_80" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_http_and_optional_ssh"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 999
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [3000, 8000, 22]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.vm.resource_group_name
  depends_on                  = [azurerm_network_security_group.vm]
}
resource "azurerm_network_security_rule" "allow_vm_egress" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allow_egress"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 998
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.vm.resource_group_name
  depends_on                  = [azurerm_network_security_group.vm]
}

resource "azurerm_subnet_network_security_group_association" "subnet_network_rules" {
  network_security_group_id = azurerm_network_security_group.vm.id
  subnet_id                 = data.azurerm_subnet.public.id
}


resource "azurerm_user_assigned_identity" "vm" {
  location            = data.azurerm_resource_group.this.location
  name                = "app_${random_id.resource_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "vm" {
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
  scope                = data.azurerm_resource_group.this.id
  role_definition_name = "Reader"
}
resource "azurerm_role_assignment" "vm_read_write_data" {
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
  scope                = azurerm_storage_account.vm_storage.id
  role_definition_name = "Storage Blob data Contributor"
}


resource "azurerm_storage_account" "vm_storage" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = data.azurerm_resource_group.this.location
  name                     = "devops${random_id.resource_suffix.hex}"
  resource_group_name      = data.azurerm_resource_group.this.name
}


resource "azurerm_storage_container" "devops" {
  name                 = "devops"
  storage_account_name = azurerm_storage_account.vm_storage.name
}

resource "random_id" "frontend_public_secret" {
  byte_length = 16
}

locals {
  docker_compose_yml = yamlencode({
    version = "3.0"
    services = {
      frontend = {
        image = "${azurerm_container_registry.app.login_server}/frontend:latest"
        ports = [
          "3000:3000"
        ]
        environment = {
          NEXT_PUBLIC_API_URL = local.backend_url
          NEXT_PUBLIC_IS_MARKDOWN = "true"
          NEXTAUTH_SECRET = random_id.frontend_public_secret.hex
          NEXTAUTH_URL = local.frontend_url
        }
      }
      model = {
        image    = "qimia/llama-zmq-server:latest"
        hostname = "model"
        environment = {

          AZURE_STORAGE_ACCOUNT_NAME = "devopsqimiaaidev"
          AZURE_CONTAINER_NAME       = "llm-foundation-models"
          AZURE_FILE_PATH            = "ggml-vicuna-7b-v1.5/ggml-model-q4_1.gguf"
          MODEL_FILE                 = "ggml-vicuna-7b-v1.5__ggml-model-q4_1.gguf"
        }
        volumes = [
          "/home/ai_admin/models:/app/models"
        ]
      }
      webapi = {
        "image" = "qimiaai27da.azurecr.io/webapi:latest"
        "ports" = [
          "${local.api_port}:8000"
        ]
        environment = {
          ENV   = var.env
          CLOUD = "azure"
          ENV_FILE_REMOTE_PATH = azurerm_storage_blob.app_config.url
        }
      }
    }
  })
}

resource "azurerm_storage_container" "logs" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.vm_storage.name
}


resource "azurerm_storage_blob" "docker_compose_file" {
  name                   = "docker-compose.yml"
  storage_account_name   = azurerm_storage_container.devops.storage_account_name
  storage_container_name = azurerm_storage_container.devops.name
  type                   = "Block"
  source_content         = local.docker_compose_yml
  content_md5            = md5(local.docker_compose_yml)
}