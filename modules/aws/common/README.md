

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_firewall_sku"></a> [firewall\_sku](#input\_firewall\_sku) | The SKU of the firewall to deploy | `string` | `"Standard"` | no |
| <a name="input_ipam_enable_private_gua"></a> [ipam\_enable\_private\_gua](#input\_ipam\_enable\_private\_gua) | Enable private GUA IPAM | `bool` | `true` | no |
| <a name="input_ipam_tier"></a> [ipam\_tier](#input\_ipam\_tier) | The tier to use for IPAM | `string` | `"advanced"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to use for all resources | `string` | n/a | yes |
| <a name="input_private_prefixes_ipv4"></a> [private\_prefixes\_ipv4](#input\_private\_prefixes\_ipv4) | A list of private prefixes to allow access to | `list(string)` | <pre>[<br>  "10.0.0.0/8",<br>  "172.16.0.0/12",<br>  "192.168.0.0/16",<br>  "100.64.0.0/10"<br>]</pre> | no |
| <a name="input_private_prefixes_ipv6"></a> [private\_prefixes\_ipv6](#input\_private\_prefixes\_ipv6) | A list of private prefixes to allow access to | `list(string)` | <pre>[<br>  "fd00::/8"<br>]</pre> | no |
| <a name="input_public_key_path"></a> [public\_key\_path](#input\_public\_key\_path) | path to public key for ec2 SSH | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to deploy resources | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | n/a |
| <a name="output_iam_instance_profile"></a> [iam\_instance\_profile](#output\_iam\_instance\_profile) | n/a |
| <a name="output_ipam_id"></a> [ipam\_id](#output\_ipam\_id) | n/a |
| <a name="output_ipv4_ipam_pool_id"></a> [ipv4\_ipam\_pool\_id](#output\_ipv4\_ipam\_pool\_id) | n/a |
| <a name="output_ipv6_ipam_pool_id"></a> [ipv6\_ipam\_pool\_id](#output\_ipv6\_ipam\_pool\_id) | n/a |
| <a name="output_key_pair_name"></a> [key\_pair\_name](#output\_key\_pair\_name) | n/a |
<!-- END_TF_DOCS -->
