variable "resource_group_name" {
  type        = string
  description = "The Azure resource group name."
}

variable "env" {
  type        = string
  description = "One of dev, preprod or prod."
}

###  VNET configuration
variable "create_vnet" {
  type        = number
  description = "Whether to create a vnet, set to 0 if it already exists."
  default     = 1
  validation {
    condition     = var.create_vnet == 0 || var.create_vnet == 1
    error_message = "The creat_vnet should be either 0 or 1."
  }
}

variable "create_subnet" {
  type        = number
  description = "Whether to create the subnets, set to 0 if they already exist."
  default     = 1
  validation {
    condition     = var.create_subnet == 0 || var.create_subnet == 1
    error_message = "The create_subnet should be either 0 or 1."
  }
}

variable "vnet_name" {
  type        = string
  description = "The virtual network name"
  default     = "qimia-ai"
}

variable "vnet_cidr" {
  type        = string
  description = "The virtual network cidr"
  default     = "10.0.0.0/16"
}

variable "public_subnet_name" {
  type    = string
  default = "public"
}

variable "private_subnet_name" {
  type    = string
  default = "private"
}

variable "db_subnet_name" {
  type    = string
  default = "database"
}

variable "public_subnet" {
  type        = string
  description = "CIDR for the resources to have public access"
  default     = "10.0.1.0/24"
}

variable "private_subnet" {
  type        = string
  description = "CIDR for the resources to have no public ingress internet access"
  default     = "10.0.128.0/24"
}

variable "db_subnet" {
  type        = string
  description = "CIDR for the resources to have only egress."
  default     = "10.0.129.0/24"
}

variable "machine_sku" {
  type        = string
  description = "The machine type to use"
  default     = "Standard_D4d_v5"
}

variable "custom_backend_dns" {
  type        = string
  description = "The custom DNS for the backend api"
  default     = ""
}

variable "custom_frontend_dns" {
  type        = string
  description = "The custom DNS for the frontend api"
  default     = ""
}

variable "vm_encryption_at_host" {
  type        = bool
  description = "Whether to enable encryption at host on the VMs."
  default     = true
}

variable "rbac_keyvault" {
  type        = bool
  description = "Whether to use RBAC for keyvault secrets access"
  default     = true
}

variable "rbac_storage" {
  type        = bool
  description = "Whether to use RBAC for accessing keys in the created storage account"
  default     = true
}

variable "ssh_cidr" {
  type        = string
  description = "The CIDR to allow for SSH access to the VMs."
  default     = "*"
}

variable "use_dockerhub" {
  type        = bool
  description = "Whether to use the dockerhub to pull the model, frontend and web api images."
  default     = false
}

variable "cuda_version" {
  type        = string
  description = "Set only if you want to use a CUDA model. eg 12.2.2, 11.7.1"
  default     = null
}

variable "model_image_version" {
  type        = string
  description = "The image revision for the model image. It'll be appended to the repository name"
  default     = "latest"
}

variable "webapi_image_version" {
  type        = string
  description = "The image revision for the webapi image. It'll be appended to the repository name"
  default     = "latest"
}

variable "frontend_image_version" {
  type        = string
  description = "The image revision for the frontend image. It'll be appended to the repository name"
  default     = "latest"
}

variable "hugging_face_model" {
  type    = string
  default = ""
}

variable "hugging_face_model_file" {
  type    = string
  default = ""
}

variable "use_gpu" {
  type        = bool
  description = "Whether to use a CUDA GPU for model deployment. The machine SKU mush support it."
}

variable "ssh_key" {
  type = string
  description = "The SSH key to use"
  default = ""
}