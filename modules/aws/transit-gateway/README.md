<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the TGW is created with the current default Amazon ASN. | `string` | `null` | no |
| <a name="input_auto_accept_shared_attachments"></a> [auto\_accept\_shared\_attachments](#input\_auto\_accept\_shared\_attachments) | Whether resource attachment requests are automatically accepted | `string` | `"enable"` | no |
| <a name="input_create_tgw"></a> [create\_tgw](#input\_create\_tgw) | Controls if TGW should be created (it affects almost all resources) | `bool` | `true` | no |
| <a name="input_default_route_table_association"></a> [default\_route\_table\_association](#input\_default\_route\_table\_association) | Whether resource attachments are automatically associated with the default association route table | `string` | `"enable"` | no |
| <a name="input_default_route_table_propagation"></a> [default\_route\_table\_propagation](#input\_default\_route\_table\_propagation) | Whether resource attachments automatically propagate routes to the default propagation route table | `string` | `"enable"` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the EC2 Transit Gateway | `string` | `null` | no |
| <a name="input_dns_support"></a> [dns\_support](#input\_dns\_support) | Should be true to enable DNS support in the TGW | `string` | `"enable"` | no |
| <a name="input_multicast_support"></a> [multicast\_support](#input\_multicast\_support) | Whether multicast support is enabled | `string` | `"disable"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all the resources as identifier | `string` | `""` | no |
| <a name="input_ram_allow_external_principals"></a> [ram\_allow\_external\_principals](#input\_ram\_allow\_external\_principals) | Indicates whether principals outside your organization can be associated with a resource share. | `bool` | `false` | no |
| <a name="input_ram_name"></a> [ram\_name](#input\_ram\_name) | The name of the resource share of TGW | `string` | `""` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to share TGW with. Possible values are an AWS account ID, an AWS Organizations Organization ARN, or an AWS Organizations Organization Unit ARN | `list(string)` | `[]` | no |
| <a name="input_ram_resource_share_arn"></a> [ram\_resource\_share\_arn](#input\_ram\_resource\_share\_arn) | ARN of RAM resource share | `string` | `null` | no |
| <a name="input_ram_tags"></a> [ram\_tags](#input\_ram\_tags) | Additional tags for the RAM | `map(string)` | `{}` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | List of route table configurations with tags | <pre>list(object({<br>    name = string<br>  }))</pre> | `[]` | no |
| <a name="input_security_group_referencing_support"></a> [security\_group\_referencing\_support](#input\_security\_group\_referencing\_support) | Whether Security Group Referencing Support is enabled | `string` | `"disable"` | no |
| <a name="input_share_tgw"></a> [share\_tgw](#input\_share\_tgw) | Whether to share your transit gateway with other accounts | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_tgw_default_route_table_tags"></a> [tgw\_default\_route\_table\_tags](#input\_tgw\_default\_route\_table\_tags) | Additional tags for the Default TGW route table | `map(string)` | `{}` | no |
| <a name="input_tgw_route_table_tags"></a> [tgw\_route\_table\_tags](#input\_tgw\_route\_table\_tags) | Additional tags for the TGW route table | `map(string)` | `{}` | no |
| <a name="input_tgw_tags"></a> [tgw\_tags](#input\_tgw\_tags) | Additional tags for the TGW | `map(string)` | `{}` | no |
| <a name="input_tgw_vpc_attachment_tags"></a> [tgw\_vpc\_attachment\_tags](#input\_tgw\_vpc\_attachment\_tags) | Additional tags for VPC attachments | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create, update, and delete timeout configurations for the transit gateway | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_cidr_blocks"></a> [transit\_gateway\_cidr\_blocks](#input\_transit\_gateway\_cidr\_blocks) | One or more IPv4 or IPv6 CIDR blocks for the transit gateway. Must be a size /24 CIDR block or larger for IPv4, or a size /64 CIDR block or larger for IPv6 | `list(string)` | `[]` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the EC2 Transit Gateway. If not provided, a new one will be created. | `string` | `null` | no |
| <a name="input_transit_gateway_route_table_id"></a> [transit\_gateway\_route\_table\_id](#input\_transit\_gateway\_route\_table\_id) | Identifier of EC2 Transit Gateway Route Table to use with the Target Gateway when reusing it between multiple TGWs | `string` | `null` | no |
| <a name="input_transit_gateway_routes"></a> [transit\_gateway\_routes](#input\_transit\_gateway\_routes) | A list of transit gateway routes to create | <pre>list(object({<br>    name             = string<br>    ipv4_prefixes    = optional(list(string), [])<br>    route_table_name = optional(string, null) # creating a new route table<br>    route_table_id   = optional(string, null) # modifying an existing route table<br>    attachment_name  = optional(string, null) # creating a new attachment<br>    attachment_id    = optional(string, null) # modifying an existing attachment<br>    blackhole        = optional(bool, false)<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_attachments"></a> [vpc\_attachments](#input\_vpc\_attachments) | A list of VPC attachments to create with the EC2 Transit Gateway | <pre>list(object({<br>    name                   = string<br>    id                     = optional(string, null) # used when modifying existing transit gateway<br>    subnet_ids             = list(string)<br>    vpc_id                 = string<br>    appliance_mode_support = optional(string, "disable")<br>    dns_support            = optional(string, "enable")<br>    ipv6_support           = optional(string, "disable")<br><br>    associated_route_table_name  = optional(string, null)     # used when creating new transit gateway<br>    associated_route_table_id    = optional(string, null)     # used when modifying existing transit gateway<br>    propagated_route_table_names = optional(list(string), []) # used when creating new transsit gateway<br>    propagated_route_table_ids   = optional(list(string), []) # used when modifying existing transit gateway<br><br>    security_group_referencing_support              = optional(string, "disable")<br>    transit_gateway_default_route_table_association = optional(bool, false)<br>    transit_gateway_default_route_table_propagation = optional(bool, false)<br><br>    vpc_routes = optional(list(object({<br>      name           = string<br>      ipv4_prefixes  = optional(list(string), [])<br>      ipv6_prefixes  = optional(list(string), [])<br>      route_table_id = string<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_vpn_ecmp_support"></a> [vpn\_ecmp\_support](#input\_vpn\_ecmp\_support) | Whether VPN Equal Cost Multipath Protocol support is enabled | `string` | `"enable"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | EC2 Transit Gateway Amazon Resource Name (ARN) |
| <a name="output_association_default_route_table_id"></a> [association\_default\_route\_table\_id](#output\_association\_default\_route\_table\_id) | Identifier of the default association route table |
| <a name="output_id"></a> [id](#output\_id) | EC2 Transit Gateway identifier |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | Identifier of the AWS account that owns the EC2 Transit Gateway |
| <a name="output_propagation_default_route_table_id"></a> [propagation\_default\_route\_table\_id](#output\_propagation\_default\_route\_table\_id) | Identifier of the default propagation route table |
| <a name="output_ram_principal_association_id"></a> [ram\_principal\_association\_id](#output\_ram\_principal\_association\_id) | The Amazon Resource Name (ARN) of the Resource Share and the principal, separated by a comma |
| <a name="output_ram_resource_share_id"></a> [ram\_resource\_share\_id](#output\_ram\_resource\_share\_id) | The Amazon Resource Name (ARN) of the resource share |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | List of EC2 Transit Gateway Route Table identifiers |
| <a name="output_route_table_association"></a> [route\_table\_association](#output\_route\_table\_association) | Map of EC2 Transit Gateway Route Table Association attributes |
| <a name="output_route_table_association_ids"></a> [route\_table\_association\_ids](#output\_route\_table\_association\_ids) | List of EC2 Transit Gateway Route Table Association identifiers |
| <a name="output_route_table_default_association_route_table"></a> [route\_table\_default\_association\_route\_table](#output\_route\_table\_default\_association\_route\_table) | Boolean whether this is the default association route table for the EC2 Transit Gateway |
| <a name="output_route_table_default_propagation_route_table"></a> [route\_table\_default\_propagation\_route\_table](#output\_route\_table\_default\_propagation\_route\_table) | Boolean whether this is the default propagation route table for the EC2 Transit Gateway |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | EC2 Transit Gateway Route Table identifiers |
| <a name="output_route_table_propagation"></a> [route\_table\_propagation](#output\_route\_table\_propagation) | Map of EC2 Transit Gateway Route Table Propagation attributes |
| <a name="output_route_table_propagation_ids"></a> [route\_table\_propagation\_ids](#output\_route\_table\_propagation\_ids) | List of EC2 Transit Gateway Route Table Propagation identifiers |
| <a name="output_vpc_attachment"></a> [vpc\_attachment](#output\_vpc\_attachment) | Map of EC2 Transit Gateway VPC Attachment attributes |
| <a name="output_vpc_attachment_ids"></a> [vpc\_attachment\_ids](#output\_vpc\_attachment\_ids) | List of EC2 Transit Gateway VPC Attachment identifiers |
<!-- END_TF_DOCS -->