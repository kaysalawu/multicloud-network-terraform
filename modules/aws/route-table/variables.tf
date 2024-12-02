
variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "region" {
  description = "The region where the resources will be created"
  type        = string
}

variable "route_tables" {
  description = "The route table object"
  type = list(object({
    vpc_id     = string
    create     = optional(bool, false)
    name       = optional(string, null) # name of the route table to create
    id         = optional(string, null) # id of existing route table
    subnet_ids = optional(list(string), [])
    gateway_id = optional(string, null)
    tags       = optional(map(any), null)
  }))
  default = []

  validation {
    condition = alltrue([
      for rt in var.route_tables : !(
        (rt.create == true && rt.id != null) ||
        (rt.create == true && rt.name == null)
      )
    ])
    error_message = "If 'create' is true, 'id' cannot be specified and 'name' must be specified."
  }
}

variable "routes" {
  description = "A list of route objects"
  type = list(object({
    route_table_name = optional(string, null)

    ipv4_prefixes = optional(list(string), [])
    ipv6_prefixes = optional(list(string), [])

    route_table_id             = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    carrier_gateway_id         = optional(string, null)
    core_network_arn           = optional(string, null)
    egress_only_gateway_id     = optional(string, null)
    gateway_id                 = optional(string, null)
    nat_gateway_id             = optional(string, null)
    local_gateway_id           = optional(string, null)
    network_interface_id       = optional(string, null)
    transit_gateway_id         = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
    vpc_peering_connection_id  = optional(string, null)

    delay_creation = optional(string, "0s")
  }))
  default = []
}
