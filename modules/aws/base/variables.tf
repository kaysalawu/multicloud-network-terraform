
variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "vpc region"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "admin_username" {
  description = "test username. please change for production"
  type        = string
  default     = "ubuntu"
}

variable "admin_password" {
  description = "test password. please change for production"
  type        = string
  default     = "Password123"
}

variable "ssh_public_key" {
  description = "sh public key data"
  type        = string
  default     = null
}

variable "private_prefixes_ipv4" {
  description = "A list of private prefixes to allow access to"
  type        = list(string)
  default     = ["10.0.0.0/8", ]
}

variable "private_prefixes_ipv6" {
  description = "A list of private prefixes to allow access to"
  type        = list(string)
  default     = ["fd00::/8"]
}

variable "cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = list(string)
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Determines whether network address usage metrics are enabled for the VPC"
  type        = bool
  default     = null
}

variable "use_ipv4_ipam_pool" {
  description = "Determines whether IPAM pool is used for IPv4 CIDR allocation"
  type        = bool
  default     = false
}

variable "use_ipv6_ipam_pool" {
  description = "Determines whether IPAM pool is used for IPv6 CIDR allocation"
  type        = bool
  default     = false
}

variable "ipv4_ipam_pool_id" {
  description = "(Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR"
  type        = string
  default     = null
}

variable "ipv4_netmask_length" {
  description = "(Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a ipv4_ipam_pool_id"
  type        = number
  default     = null
}

variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block"
  type        = bool
  default     = false
}

variable "ipv6_cidr" {
  description = "(Optional) IPv6 CIDR block to request from an IPAM Pool. Can be set explicitly or derived from IPAM using `ipv6_netmask_length`"
  type        = list(string)
  default     = null
}

variable "ipv6_ipam_pool_id" {
  description = "(Optional) IPAM Pool ID for a IPv6 pool. Conflicts with `assign_generated_ipv6_cidr_block`"
  type        = string
  default     = null
}

variable "ipv6_netmask_length" {
  description = "(Optional) Netmask length to request from IPAM Pool. Conflicts with `ipv6_cidr_block`. This can be omitted if IPAM pool as a `allocation_default_netmask_length` set. Valid values: `56`"
  type        = number
  default     = null
}

variable "ipv6_cidr_block_network_border_group" {
  description = "By default when an IPv6 CIDR is assigned to a VPC a default ipv6_cidr_block_network_border_group will be set to the region of the VPC. This can be changed to restrict advertisement of public addresses to specific Network Border Groups such as LocalZones"
  type        = string
  default     = null
}

variable "dhcp_options" {
  description = "A map of DHCP options to assign to the VPC"
  type = object({
    enable              = optional(bool, false)
    domain_name         = optional(string, null)
    domain_name_servers = optional(list(string), ["AmazonProvidedDNS"])
    ntp_servers         = optional(list(string), null)
  })
  default = {
    domain_name_servers = ["AmazonProvidedDNS", ]
  }
}

variable "subnets" {
  description = "A map of subnet configurations"
  type = map(object({
    cidr          = string
    ipv6_cidr     = optional(string, null)
    ipv6_newbits  = optional(number, 8)
    ipv6_netnum   = optional(string, 0)
    az            = optional(string, "a")
    scope         = optional(string, "private")
    public_natgw  = optional(bool, false)
    private_natgw = optional(bool, false)

    map_public_ip_on_launch = optional(bool, false)
  }))
  default = {}
}

variable "bastion_config" {
  description = "A map of bastion configuration"
  type = object({
    enable               = bool
    instance_type        = optional(string, "t2.micro")
    key_name             = optional(string, null)
    private_ips          = optional(list(string), [])
    ipv6_addresses       = optional(list(string), [])
    iam_instance_profile = optional(string, null)
    public_dns_zone_name = optional(string, null)
    dns_prefix           = optional(string, null)
  })
  default = {
    enable = false
  }
}

variable "private_dns_zone_name" {
  description = "The name of the private DNS zone to associate with the VPC"
  type        = string
  default     = null
}

variable "private_dns_zone_vpc_associations" {
  description = "A list of VPC IDs to associate with the private DNS zone"
  type        = list(string)
  default     = []
}

variable "private_dns_config" {
  description = "A map of DNS configuration"
  type = object({
    zone_name = optional(string, null)
  })
  default = {}
}

variable "nat_config" {
  description = "A list of NAT configuration"
  type = list(object({
    scope      = string
    subnet     = string
    private_ip = optional(string, null)
  }))
  default = []
}

variable "route_table_config" {
  description = "A list of route table configuration"
  type = list(object({
    scope   = string
    subnets = optional(list(string), [])
    routes = optional(list(object({
      ipv4_cidr          = optional(string, null)
      ipv6_cidr          = optional(string, null)
      nat_gateway        = optional(bool, false)
      internet_gateway   = optional(bool, false)
      nat_gateway_subnet = optional(string, null)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for rt in var.route_table_config : alltrue([
        for route in rt.routes : !(route.ipv4_cidr != null && route.ipv6_cidr != null)
      ])
    ])
    error_message = "Only one of ipv4_cidr or ipv6_cidr can be specified per route."
  }

  validation {
    condition = alltrue([
      for rt in var.route_table_config : alltrue([
        for route in rt.routes : !(route.ipv6_cidr != null && route.nat_gateway == true)
      ])
    ])
    error_message = "If ipv6_cidr is specified, nat_gateway cannot be true in any route."
  }
}

variable "create_internet_gateway" {
  description = "Should be true to create an internet gateway"
  type        = bool
  default     = true
}

variable "dns_resolver_config" {
  description = "DNS resolver configuration"
  type = list(object({
    inbound = list(object({
      subnet = string
      ip     = optional(string, null)
    }))
    outbound = list(object({
      subnet = string
      ip     = optional(string, null)
    }))
    rules = optional(list(object({
      domain     = string
      target_ips = list(string)
      rule_type  = optional(string, "FORWARD")
    })), [])
    additional_associated_vpc_ids = optional(list(string), [])
  }))
  default = []
}
