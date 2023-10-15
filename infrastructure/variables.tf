variable "resource_group_name" {
  type        = string
  description = "The Azure resource group name."
}

variable "env" {
  type        = string
  description = "One of dev, preprod or prod."
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for devops purposes"
}


###  VNET configuration
variable "existing_vnet" {
  type = bool
  description = "Whether to create a new Virtual Network, set to false if it already exists."
  default = false
}

variable "vnet_name" {
  type = string
  description = "The virtual network name"
  default = "qimia-ai"
}

variable "vnet_cidr" {
  type = string
  description = "The virtual network cidr"
  default = "10.0.0.0/16"
}

variable "public_subnet_name" {
  type = string
  default = "public"
}

variable "private_subnet_name" {
  type = string
  default = "private"
}

variable "db_subnet_name" {
  type = string
  default = "database"
}

variable "public_subnet" {
  type        = string
  description = "CIDR for the resources to have public access"
  default = "10.0.1.0/24"
}

variable "private_subnet" {
  type        = string
  description = "CIDR for the resources to have no public ingress internet access"
  default = "10.0.128.0/24"
}

variable "db_subnet" {
  type        = string
  description = "CIDR for the resources to have only egress."
  default = "10.0.129.0/24"
}

variable "machine_sku" {
  type        = string
  description = "The machine type to use"
  default     = "Standard_D4d_v5"
}