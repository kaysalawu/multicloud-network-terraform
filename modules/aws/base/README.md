<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | test password. please change for production | `string` | `"Password123"` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | test username. please change for production | `string` | `"ubuntu"` | no |
| <a name="input_bastion_config"></a> [bastion\_config](#input\_bastion\_config) | A map of bastion configuration | <pre>object({<br>    enable               = bool<br>    instance_type        = optional(string, "t2.micro")<br>    key_name             = optional(string, null)<br>    private_ips          = optional(list(string), [])<br>    ipv6_addresses       = optional(list(string), [])<br>    iam_instance_profile = optional(string, null)<br>    public_dns_zone_name = optional(string, null)<br>    dns_prefix           = optional(string, null)<br>  })</pre> | <pre>{<br>  "enable": false<br>}</pre> | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | (Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id` | `list(string)` | n/a | yes |
| <a name="input_create_internet_gateway"></a> [create\_internet\_gateway](#input\_create\_internet\_gateway) | Should be true to create an internet gateway | `bool` | `true` | no |
| <a name="input_dhcp_options"></a> [dhcp\_options](#input\_dhcp\_options) | A map of DHCP options to assign to the VPC | <pre>object({<br>    enable              = optional(bool, false)<br>    domain_name         = optional(string, null)<br>    domain_name_servers = optional(list(string), ["AmazonProvidedDNS"])<br>    ntp_servers         = optional(list(string), null)<br>  })</pre> | <pre>{<br>  "domain_name_servers": [<br>    "AmazonProvidedDNS"<br>  ]<br>}</pre> | no |
| <a name="input_dns_resolver_config"></a> [dns\_resolver\_config](#input\_dns\_resolver\_config) | DNS resolver configuration | <pre>list(object({<br>    inbound = list(object({<br>      subnet = string<br>      ip     = optional(string, null)<br>    }))<br>    outbound = list(object({<br>      subnet = string<br>      ip     = optional(string, null)<br>    }))<br>    rules = optional(list(object({<br>      domain     = string<br>      target_ips = list(string)<br>      rule_type  = optional(string, "FORWARD")<br>    })), [])<br>    additional_associated_vpc_ids = optional(list(string), [])<br>  }))</pre> | `[]` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block | `bool` | `false` | no |
| <a name="input_enable_network_address_usage_metrics"></a> [enable\_network\_address\_usage\_metrics](#input\_enable\_network\_address\_usage\_metrics) | Determines whether network address usage metrics are enabled for the VPC | `bool` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_ipv4_ipam_pool_id"></a> [ipv4\_ipam\_pool\_id](#input\_ipv4\_ipam\_pool\_id) | (Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR | `string` | `null` | no |
| <a name="input_ipv4_netmask_length"></a> [ipv4\_netmask\_length](#input\_ipv4\_netmask\_length) | (Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a ipv4\_ipam\_pool\_id | `number` | `null` | no |
| <a name="input_ipv6_cidr"></a> [ipv6\_cidr](#input\_ipv6\_cidr) | (Optional) IPv6 CIDR block to request from an IPAM Pool. Can be set explicitly or derived from IPAM using `ipv6_netmask_length` | `list(string)` | `null` | no |
| <a name="input_ipv6_cidr_block_network_border_group"></a> [ipv6\_cidr\_block\_network\_border\_group](#input\_ipv6\_cidr\_block\_network\_border\_group) | By default when an IPv6 CIDR is assigned to a VPC a default ipv6\_cidr\_block\_network\_border\_group will be set to the region of the VPC. This can be changed to restrict advertisement of public addresses to specific Network Border Groups such as LocalZones | `string` | `null` | no |
| <a name="input_ipv6_ipam_pool_id"></a> [ipv6\_ipam\_pool\_id](#input\_ipv6\_ipam\_pool\_id) | (Optional) IPAM Pool ID for a IPv6 pool. Conflicts with `assign_generated_ipv6_cidr_block` | `string` | `null` | no |
| <a name="input_ipv6_netmask_length"></a> [ipv6\_netmask\_length](#input\_ipv6\_netmask\_length) | (Optional) Netmask length to request from IPAM Pool. Conflicts with `ipv6_cidr_block`. This can be omitted if IPAM pool as a `allocation_default_netmask_length` set. Valid values: `56` | `number` | `null` | no |
| <a name="input_nat_config"></a> [nat\_config](#input\_nat\_config) | A list of NAT configuration | <pre>list(object({<br>    scope      = string<br>    subnet     = string<br>    private_ip = optional(string, null)<br>  }))</pre> | `[]` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_private_dns_config"></a> [private\_dns\_config](#input\_private\_dns\_config) | A map of DNS configuration | <pre>object({<br>    zone_name = optional(string, null)<br>  })</pre> | `{}` | no |
| <a name="input_private_dns_zone_name"></a> [private\_dns\_zone\_name](#input\_private\_dns\_zone\_name) | The name of the private DNS zone to associate with the VPC | `string` | `null` | no |
| <a name="input_private_dns_zone_vpc_associations"></a> [private\_dns\_zone\_vpc\_associations](#input\_private\_dns\_zone\_vpc\_associations) | A list of VPC IDs to associate with the private DNS zone | `list(string)` | `[]` | no |
| <a name="input_private_prefixes_ipv4"></a> [private\_prefixes\_ipv4](#input\_private\_prefixes\_ipv4) | A list of private prefixes to allow access to | `list(string)` | <pre>[<br>  "10.0.0.0/8"<br>]</pre> | no |
| <a name="input_private_prefixes_ipv6"></a> [private\_prefixes\_ipv6](#input\_private\_prefixes\_ipv6) | A list of private prefixes to allow access to | `list(string)` | <pre>[<br>  "fd00::/8"<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | vpc region | `string` | n/a | yes |
| <a name="input_route_table_config"></a> [route\_table\_config](#input\_route\_table\_config) | A list of route table configuration | <pre>list(object({<br>    scope   = string<br>    subnets = optional(list(string), [])<br>    routes = optional(list(object({<br>      ipv4_cidr          = optional(string, null)<br>      ipv6_cidr          = optional(string, null)<br>      nat_gateway        = optional(bool, false)<br>      internet_gateway   = optional(bool, false)<br>      nat_gateway_subnet = optional(string, null)<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | sh public key data | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A map of subnet configurations | <pre>map(object({<br>    cidr          = string<br>    ipv6_cidr     = optional(string, null)<br>    ipv6_newbits  = optional(number, 8)<br>    ipv6_netnum   = optional(string, 0)<br>    az            = optional(string, "a")<br>    scope         = optional(string, "private")<br>    public_natgw  = optional(bool, false)<br>    private_natgw = optional(bool, false)<br><br>    map_public_ip_on_launch = optional(bool, false)<br>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_use_ipv4_ipam_pool"></a> [use\_ipv4\_ipam\_pool](#input\_use\_ipv4\_ipam\_pool) | Determines whether IPAM pool is used for IPv4 CIDR allocation | `bool` | `false` | no |
| <a name="input_use_ipv6_ipam_pool"></a> [use\_ipv6\_ipam\_pool](#input\_use\_ipv6\_ipam\_pool) | Determines whether IPAM pool is used for IPv6 CIDR allocation | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_id"></a> [bastion\_id](#output\_bastion\_id) | n/a |
| <a name="output_bastion_sg_id"></a> [bastion\_security\_group\_id](#output\_bastion\_security\_group\_id) | n/a |
| <a name="output_ec2_sg_id"></a> [ec2\_security\_group\_id](#output\_ec2\_security\_group\_id) | n/a |
| <a name="output_internet_gateway"></a> [internet\_gateway](#output\_internet\_gateway) | n/a |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | n/a |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | n/a |
| <a name="output_nat_gateways"></a> [nat\_gateways](#output\_nat\_gateways) | n/a |
| <a name="output_nva_sg_id"></a> [nva\_security\_group\_id](#output\_nva\_security\_group\_id) | n/a |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | n/a |
| <a name="output_route_tables"></a> [route\_tables](#output\_route\_tables) | n/a |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | n/a |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
| <a name="output_vpc_ipv6_cidr_block"></a> [vpc\_ipv6\_cidr\_block](#output\_vpc\_ipv6\_cidr\_block) | n/a |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | n/a |
<!-- END_TF_DOCS -->
