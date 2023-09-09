variable "resource_group_name" {
  type        = string
  description = "The Azure resource group name. Ideally defined in the <env>.tfvars file"
}

variable "env" {
  type        = string
  description = "One of dev, preprod or prod."
}

variable "public_subnets" {
  type        = list(string)
  description = "List of CIDR for the resources to have public access"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of CIDR for the resources to have no public ingress internet access"
}
variable "db_subnets" {
  type        = list(string)
  description = "List of CIDR for the resources to have only egress."
}

variable "machine_sku" {
  type        = string
  description = "The machine type to use"
  default     = "Standard_D4d_v5"
}