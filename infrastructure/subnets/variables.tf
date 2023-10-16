
variable "resource_group_name" {
  type = string
  description = "The virtual network name"
}
variable "vnet_name" {
  type = string
  description = "The virtual network name"
}

variable "vnet_cidr" {
  type = string
  description = "The virtual network cidr"
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
}

variable "private_subnet" {
  type        = string
  description = "CIDR for the resources to have no public ingress internet access"
}

variable "db_subnet" {
  type        = string
  description = "CIDR for the resources to have only egress."
}