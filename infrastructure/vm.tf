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

  dynamic "admin_ssh_key" {
    for_each = fileexists("${path.module}/../qimia-ai.pub") == true ? toset([1]) : toset([])
    content {
    public_key = file("${path.module}/../qimia-ai.pub")
    username   = local.admin_username
    }
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
  encryption_at_host_enabled      = var.vm_encryption_at_host
  tags = {
    env = var.env
  }
  depends_on = [data.azurerm_subnet.private, azurerm_network_security_group.vm, azurerm_user_assigned_identity.vm]
}

resource "random_password" "vm_admin_password" {
  length  = 32
  special = false
}

resource azurerm_key_vault_secret "vm_admin_password" {
  key_vault_id = azurerm_key_vault.app_secrets.id
  name = "vm-admin-password"
  value = random_password.vm_admin_password.result
}

resource "azurerm_storage_blob" "bootstrap_script" {
  name                   = "bootstrap.sh"
  storage_account_name   = azurerm_storage_container.devops.storage_account_name
  storage_container_name = azurerm_storage_container.devops.name
  type                   = "Block"
  source                 = "${path.module}/bootstrap.sh"
  content_md5            = filemd5("${path.module}/bootstrap.sh")
}

resource "azurerm_storage_blob" "sync_logs_script" {
  name                   = "sync-logs.sh"
  storage_account_name   = azurerm_storage_container.devops.storage_account_name
  storage_container_name = azurerm_storage_container.devops.name
  type                   = "Block"
  source                 = "${path.module}/sync-logs.sh"
  content_md5            = filemd5("${path.module}/sync-logs.sh")
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

resource "azurerm_network_security_rule" "allow_http" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_http_and_optional_ssh"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 999
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [3000, 8000]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.vm.resource_group_name
  depends_on                  = [azurerm_network_security_group.vm]
}

resource "azurerm_network_security_rule" "allow_ssh" {
  count = var.ssh_cidr == "" ? 0 : 1
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_ssh"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 998
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [22]
  source_address_prefix       = var.ssh_cidr
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


resource "azurerm_role_assignment" "vm_read_write_data" {
  count = var.rbac_storage ? 1 : 0
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

  frontend_image = var.use_dockerhub ? "qimia/llama-server-web-ui" : "${azurerm_container_registry.app.login_server}/frontend"
  frontend_image_full = "${local.frontend_image}:${var.frontend_image_version}"

  webapi_image = var.use_dockerhub ? "qimia/llama-server-web-api" : "${azurerm_container_registry.app.login_server}/webapi"
  webapi_image_full = "${local.webapi_image}:${var.webapi_image_version}"

  model_image = var.use_dockerhub ? "qimia/llama-zmq-server" : "${azurerm_container_registry.app.login_server}/llama-zmq-server"
  model_image_with_cuda = join("", [local.model_image, var.cuda_version == null ? "" : "-cuda-${var.cuda_version}"])

  model_image_full = "${local.model_image_with_cuda}:${var.model_image_version}"

  docker_compose_yml = yamlencode({
    version = "3.0"
    services = {
      frontend = {
        image = local.frontend_image_full
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
        image    = local.model_image_full
        hostname = "model"
        environment = {
          HUGGING_FACE_MODEL         = var.hugging_face_model
          HUGGING_FACE_MODEL_FILE    = var.hugging_face_model_file
          MODEL_FILE                 = "ggml-vicuna-7b-v1.5__ggml-model-q4_1.gguf"
        }
        volumes = [
          "/home/ai_admin/models:/app/models"
        ]
      }
      webapi = {
        "image" = local.webapi_image_full
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

output "vm_user_identity" {
  value = azurerm_user_assigned_identity.vm.name
}

output "storage_account_name" {
  value = azurerm_storage_account.vm_storage.name
}