
locals {
  prefix          = var.prefix == "" ? "" : format("%s-", var.prefix)
  public_subnets  = { for k, v in var.subnets : k => v if v.scope == "public" }
  private_subnets = { for k, v in var.subnets : k => v if v.scope == "private" }

  route_table_subnet_association = flatten([for k, v in local.route_table_subnet_association_ : v])
  route_table_subnet_association_ = {
    for rt in var.route_table_config : rt.scope => [
      for subnet in rt.subnets : {
        subnet_id      = aws_subnet.this[subnet].id
        route_table_id = aws_route_table.this[rt.scope].id
      }
    ]
  }
  routes = flatten([
    for rt in var.route_table_config : [
      for route in rt.routes : {
        scope                       = rt.scope
        destination_cidr_block      = try(route.ipv4_cidr, null)
        destination_ipv6_cidr_block = try(route.ipv6_cidr, null)

        gateway_id     = var.create_internet_gateway && route.internet_gateway ? aws_internet_gateway.this.0.id : null
        nat_gateway_id = route.nat_gateway ? aws_nat_gateway.natgw[route.nat_gateway_subnet].id : null

        route_table_id             = try(aws_route_table.this[rt.scope].id, null)
        destination_prefix_list_id = try(route.destination_prefix_list_id, null)
        carrier_gateway_id         = try(route.carrier_gateway_id, null)
        core_network_arn           = try(route.core_network_arn, null)
        egress_only_gateway_id     = try(route.egress_only_gateway_id, null)
        local_gateway_id           = try(route.local_gateway_id, null)
        network_interface_id       = try(route.network_interface_id, null)
        transit_gateway_id         = try(route.transit_gateway_id, null)
        vpc_endpoint_id            = try(route.vpc_endpoint_id, null)
        vpc_peering_connection_id  = try(route.vpc_peering_connection_id, null)
    }]
  ])
  additional_associated_vpc_ids = flatten([
    for rule in try(var.dns_resolver_config.0.rules, []) : [
      for vpc_id in var.dns_resolver_config.0.additional_associated_vpc_ids : {
        key    = "${rule.domain}--${vpc_id}"
        vpc_id = vpc_id
        domain = rule.domain
      }
    ]
  ])
}

####################################################
# vpc
####################################################

# ipam

resource "aws_vpc_ipam_pool_cidr" "ipv4" {
  count        = var.use_ipv4_ipam_pool ? 1 : 0
  ipam_pool_id = var.ipv4_ipam_pool_id
  cidr         = var.cidr.0
}

resource "aws_vpc_ipam_pool_cidr" "ipv6" {
  count        = var.enable_ipv6 && var.use_ipv6_ipam_pool ? 1 : 0
  ipam_pool_id = var.ipv6_ipam_pool_id
  cidr         = var.ipv6_cidr.0
}

# vpc

resource "aws_vpc" "this" {
  cidr_block          = var.use_ipv4_ipam_pool ? null : var.cidr.0
  ipv4_ipam_pool_id   = var.use_ipv4_ipam_pool ? var.ipv4_ipam_pool_id : null
  ipv4_netmask_length = var.use_ipv4_ipam_pool ? var.ipv4_netmask_length : null

  assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipv6_ipam_pool ? true : null
  ipv6_cidr_block                      = var.enable_ipv6 && var.use_ipv6_ipam_pool ? var.ipv6_cidr.0 : null
  ipv6_ipam_pool_id                    = var.enable_ipv6 && var.use_ipv6_ipam_pool ? var.ipv6_ipam_pool_id : null
  ipv6_netmask_length                  = var.enable_ipv6 && var.use_ipv6_ipam_pool ? var.ipv6_netmask_length : null
  ipv6_cidr_block_network_border_group = var.enable_ipv6 && !var.use_ipv6_ipam_pool ? var.region : null

  instance_tenancy                     = var.instance_tenancy
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(var.tags,
    { Name = "${local.prefix}vpc" }
  )
  depends_on = [
    aws_vpc_ipam_pool_cidr.ipv4,
    aws_vpc_ipam_pool_cidr.ipv6,
  ]
}

# additional cidr blocks

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count      = length(var.cidr) > 1 ? length(var.cidr) - 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.cidr[count.index + 1]
}

# dhcp options

resource "aws_vpc_dhcp_options" "this" {
  count               = var.dhcp_options.enable ? 1 : 0
  domain_name         = var.dhcp_options.domain_name
  domain_name_servers = var.dhcp_options.domain_name_servers
  ntp_servers         = var.dhcp_options.ntp_servers

  tags = {
    Name = "${local.prefix}dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  count           = var.dhcp_options.enable ? 1 : 0
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[count.index].id
}

####################################################
# subnets
####################################################

resource "aws_subnet" "this" {
  for_each          = var.subnets
  availability_zone = "${var.region}${each.value.az}"
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr

  ipv6_cidr_block = (
    var.enable_ipv6 && each.value.ipv6_cidr != null ?
    cidrsubnet(aws_vpc.this.ipv6_cidr_block, each.value.ipv6_newbits, each.value.ipv6_netnum) :
    null
  )
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(var.tags,
    {
      Name  = each.key
      Scope = each.value.scope
      Az    = each.value.az
    }
  )
}

####################################################
# route tables
####################################################

resource "aws_route_table" "this" {
  for_each = { for v in var.route_table_config : v.scope => v }
  vpc_id   = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}rtb/${each.value.scope}"
      Scope = each.value.scope
    }
  )
}

resource "aws_route_table_association" "this" {
  count          = length(local.route_table_subnet_association)
  subnet_id      = local.route_table_subnet_association[count.index].subnet_id
  route_table_id = local.route_table_subnet_association[count.index].route_table_id
}

####################################################
# internet gateway
####################################################

# gateway

resource "aws_internet_gateway" "this" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Name = "${local.prefix}igw"
    }
  )
}

# routes

resource "aws_route" "this" {
  for_each = { for r in local.routes :
    "${r.scope}-${coalesce(r.destination_cidr_block, r.destination_ipv6_cidr_block)}" => r
  }
  route_table_id              = each.value.route_table_id
  destination_cidr_block      = each.value.destination_cidr_block
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block

  gateway_id     = each.value.gateway_id
  nat_gateway_id = each.value.nat_gateway_id

  destination_prefix_list_id = try(each.value.destination_prefix_list_id, null)
  carrier_gateway_id         = try(each.value.carrier_gateway_id, null)
  core_network_arn           = try(each.value.core_network_arn, null)
  egress_only_gateway_id     = try(each.value.egress_only_gateway_id, null)
  local_gateway_id           = try(each.value.local_gateway_id, null)
  network_interface_id       = try(each.value.network_interface_id, null)
  transit_gateway_id         = try(each.value.transit_gateway_id, null)
  vpc_endpoint_id            = try(each.value.vpc_endpoint_id, null)
  vpc_peering_connection_id  = try(each.value.vpc_peering_connection_id, null)
}

####################################################
# nat
####################################################

# address

resource "aws_eip" "natgw" {
  for_each = { for v in var.nat_config : v.subnet => v if v.scope == "public" }
  domain   = "vpc"
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}eip-natgw-${var.subnets[each.key].az}"
      Scope = "public"
    }
  )
}

# gateway

resource "aws_nat_gateway" "natgw" {
  for_each          = { for v in var.nat_config : v.subnet => v }
  connectivity_type = each.value.scope
  allocation_id     = each.value.scope == "public" ? aws_eip.natgw[each.key].id : null
  private_ip        = each.value.scope == "private" ? each.value.private_ip : null
  subnet_id         = aws_subnet.this[each.key].id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}natgw-${each.key}-${var.subnets[each.key].az}"
      Scope = "public"
      Az    = var.subnets[each.key].az
    }
  )
  depends_on = [aws_internet_gateway.this, ]
}

####################################################
# private dns
####################################################

# association

resource "aws_route53_zone_association" "this" {
  count   = var.private_dns_config.zone_name != null ? 1 : 0
  zone_id = data.aws_route53_zone.private.0.zone_id
  vpc_id  = aws_vpc.this.id
}

# dns namespace

# resource "aws_service_discovery_private_dns_namespace" "this" {
#   count       = var.private_dns_config.enable_service_discovery ? 1 : 0
#   name        = var.private_dns_config.zone_name
#   description = "Private DNS namespace for ${var.private_dns_config.zone_name}"
#   vpc         = aws_vpc.this.id
# }

# # dns service

# resource "aws_service_discovery_service" "dns" {
#   name = "dns"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.this[0].id

#     dns_records {
#       ttl  = 10
#       type = "A"
#     }

#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }
# }

####################################################
# dns resolver
####################################################

# inbound

resource "aws_route53_resolver_endpoint" "inbound" {
  count              = length(var.dns_resolver_config) > 0 ? 1 : 0
  name               = "${local.prefix}inbound-ep"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.ec2_sg.id, ]

  dynamic "ip_address" {
    for_each = { for v in var.dns_resolver_config.0.inbound : v.subnet => v }
    content {
      subnet_id = aws_subnet.this[ip_address.value.subnet].id
      ip        = ip_address.value.ip
    }
  }
  tags = merge(var.tags,
    { Name = "${local.prefix}inbound-ep" }
  )
}

# outbound

resource "aws_route53_resolver_endpoint" "outbound" {
  count              = length(var.dns_resolver_config) > 0 ? 1 : 0
  name               = "${local.prefix}outbound-ep"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.ec2_sg.id, ]

  dynamic "ip_address" {
    for_each = { for v in var.dns_resolver_config.0.outbound : v.subnet => v }
    content {
      subnet_id = aws_subnet.this[ip_address.value.subnet].id
      ip        = ip_address.value.ip
    }
  }
  tags = merge(var.tags,
    { Name = "${local.prefix}outbound-ep" }
  )
}

# forwarding rules

resource "aws_route53_resolver_rule" "this" {
  for_each             = { for v in try(var.dns_resolver_config.0.rules, []) : v.domain => v if length(var.dns_resolver_config) > 0 }
  name                 = replace(each.value.domain, ".", "-")
  domain_name          = each.value.domain
  rule_type            = each.value.rule_type
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.0.id

  dynamic "target_ip" {
    for_each = each.value.target_ips
    content {
      ip = target_ip.value
    }
  }
  tags = merge(var.tags,
    { Name = each.value.domain }
  )
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each         = { for v in try(var.dns_resolver_config.0.rules, []) : v.domain => v if length(var.dns_resolver_config) > 0 }
  resolver_rule_id = aws_route53_resolver_rule.this[each.key].id
  vpc_id           = aws_vpc.this.id
}

resource "aws_route53_resolver_rule_association" "additional" {
  count            = length(local.additional_associated_vpc_ids)
  resolver_rule_id = aws_route53_resolver_rule.this[local.additional_associated_vpc_ids[count.index].domain].id
  vpc_id           = local.additional_associated_vpc_ids[count.index].vpc_id
}

####################################################
# bastion
####################################################

# server
#--------------------------

locals {
  bastion_startup = templatefile("${path.module}/scripts/bastion.sh", {})
}

module "bastion" {
  count                = var.bastion_config.enable ? 1 : 0
  source               = "../ec2"
  name                 = "${local.prefix}bastion"
  availability_zone    = "${var.region}a"
  iam_instance_profile = var.bastion_config.iam_instance_profile
  ami                  = data.aws_ami.ubuntu.id
  key_name             = var.bastion_config.key_name
  user_data            = base64encode(local.bastion_startup)

  tags = merge(var.tags,
    {
      Name  = "${local.prefix}bastion"
      Scope = "public"
    }
  )

  interfaces = [
    {
      name               = "${local.prefix}bastion-untrust"
      subnet_id          = aws_subnet.this["UntrustSubnetA"].id
      private_ips        = var.bastion_config.private_ips
      security_group_ids = [aws_security_group.bastion_sg.id, ]
      create_eip         = true
    }
  ]
}

# dns zone record
#--------------------------

# public

resource "aws_route53_record" "bastion_public" {
  count   = var.bastion_config.enable && var.bastion_config.public_dns_zone_name != null ? 1 : 0
  zone_id = data.aws_route53_zone.public_bastion.0.zone_id
  name = (var.bastion_config.dns_prefix != null ?
    "${var.bastion_config.dns_prefix}.${data.aws_route53_zone.public_bastion.0.name}" :
    "${local.prefix}bastion.${data.aws_route53_zone.public_bastion.0.name}"
  )
  type    = "A"
  ttl     = "300"
  records = [module.bastion[0].public_ips["${local.prefix}bastion-untrust"], ]
}
