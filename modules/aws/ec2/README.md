<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | ami id | `string` | n/a | yes |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | availability zone | `string` | n/a | yes |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | enable ipv6 for the ec2 instance | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | iam instance profile | `string` | `null` | no |
| <a name="input_instance_metadata_tags"></a> [instance\_metadata\_tags](#input\_instance\_metadata\_tags) | enable instance metadata tags | `string` | `"enabled"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | instance type | `string` | `"t3.micro"` | no |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | list of interfaces | <pre>list(object({<br>    name               = string<br>    subnet_id          = string<br>    private_ips        = optional(list(string), [])<br>    security_group_ids = optional(list(string), [])<br>    ipv6_addresses     = optional(list(string), [])<br>    create_eip         = optional(bool, false)<br>    eip_id             = optional(string, null)<br>    eip_tag_name       = optional(string, null)<br>    public_ip          = optional(string, null)<br>    source_dest_check  = optional(bool, true)<br>    dns_config = optional(object({<br>      public    = optional(string, false)<br>      zone_name = optional(string, null)<br>      name      = optional(string, null)<br>      type      = optional(string, "A")<br>      ttl       = optional(number, 300)<br>    }), {})<br>  }))</pre> | `[]` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | key pair name | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | ec2 instance name. also used as prefix for other resources | `string` | n/a | yes |
| <a name="input_source_dest_check"></a> [source\_dest\_check](#input\_source\_dest\_check) | enable/disable source/dest check | `bool` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | user data for the ec2 instance | `string` | `null` | no |
| <a name="input_vpc_sg_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | vpc security group ids | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | n/a |
| <a name="output_interface_ids"></a> [interface\_ids](#output\_interface\_ids) | n/a |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | n/a |
| <a name="output_private_ips"></a> [private\_ips](#output\_private\_ips) | n/a |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | n/a |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | n/a |
<!-- END_TF_DOCS -->
