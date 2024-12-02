

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | The region where the resources will be created | `string` | n/a | yes |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | The route table object | <pre>list(object({<br>    vpc_id     = string<br>    create     = optional(bool, false)<br>    name       = optional(string, null) # name of the route table to create<br>    id         = optional(string, null) # id of existing route table<br>    subnet_ids = optional(list(string), [])<br>    gateway_id = optional(string, null)<br>    tags       = optional(map(any), null)<br>  }))</pre> | `[]` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | A list of route objects | <pre>list(object({<br>    route_table_name = optional(string, null)<br><br>    ipv4_prefixes = optional(list(string), [])<br>    ipv6_prefixes = optional(list(string), [])<br><br>    route_table_id             = optional(string, null)<br>    destination_prefix_list_id = optional(string, null)<br>    carrier_gateway_id         = optional(string, null)<br>    core_network_arn           = optional(string, null)<br>    egress_only_gateway_id     = optional(string, null)<br>    gateway_id                 = optional(string, null)<br>    nat_gateway_id             = optional(string, null)<br>    local_gateway_id           = optional(string, null)<br>    network_interface_id       = optional(string, null)<br>    transit_gateway_id         = optional(string, null)<br>    vpc_endpoint_id            = optional(string, null)<br>    vpc_peering_connection_id  = optional(string, null)<br><br>    delay_creation = optional(string, "0s")<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
