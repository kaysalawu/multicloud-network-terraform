
variable "prefix" {
  description = "The prefix to use for all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "firewall_sku" {
  description = "The SKU of the firewall to deploy"
  type        = string
  default     = "Standard"
}

variable "private_prefixes_ipv4" {
  description = "A list of private prefixes to allow access to"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "100.64.0.0/10"]
}

variable "private_prefixes_ipv6" {
  description = "A list of private prefixes to allow access to"
  type        = list(string)
  default     = ["fd00::/8"]
}

variable "ipam_enable_private_gua" {
  description = "Enable private GUA IPAM"
  type        = bool
  default     = true
}

variable "ipam_tier" {
  description = "The tier to use for IPAM"
  type        = string
  default     = "advanced"
}

variable "public_key_path" {
  description = "path to public key for ec2 SSH"
}
