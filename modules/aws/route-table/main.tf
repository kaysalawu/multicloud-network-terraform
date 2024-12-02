
locals {
  subnet_ids = flatten([for k, v in local.subnet_ids_ : v])
  subnet_ids_ = {
    for v in var.route_tables : v.name => [
      for subnet_id in v.subnet_ids : {
        create    = try(v.create, false)
        name      = try(v.name, null)
        id        = try(v.id, null)
        subnet_id = try(subnet_id, null)
      }
    ]
  }
  routes_ipv4 = flatten([
    for v in var.routes : [
      for prefix in v.ipv4_prefixes : {
        destination_cidr_block = prefix

        route_table_id             = try(v.route_table_id, null)
        destination_prefix_list_id = try(v.destination_prefix_list_id, null)
        carrier_gateway_id         = try(v.carrier_gateway_id, null)
        core_network_arn           = try(v.core_network_arn, null)
        egress_only_gateway_id     = try(v.egress_only_gateway_id, null)
        gateway_id                 = try(v.gateway_id, null)
        nat_gateway_id             = try(v.nat_gateway_id, null)
        local_gateway_id           = try(v.local_gateway_id, null)
        network_interface_id       = try(v.network_interface_id, null)
        transit_gateway_id         = try(v.transit_gateway_id, null)
        vpc_endpoint_id            = try(v.vpc_endpoint_id, null)
        vpc_peering_connection_id  = try(v.vpc_peering_connection_id, null)
      }
    ]
  ])
  routes_ipv6 = flatten([
    for v in var.routes : [
      for prefix in v.ipv6_prefixes : {
        destination_ipv6_cidr_block = prefix

        route_table_id             = try(v.route_table_id, null)
        destination_prefix_list_id = try(v.destination_prefix_list_id, null)
        carrier_gateway_id         = try(v.carrier_gateway_id, null)
        core_network_arn           = try(v.core_network_arn, null)
        egress_only_gateway_id     = try(v.egress_only_gateway_id, null)
        gateway_id                 = try(v.gateway_id, null)
        nat_gateway_id             = try(v.nat_gateway_id, null)
        local_gateway_id           = try(v.local_gateway_id, null)
        network_interface_id       = try(v.network_interface_id, null)
        transit_gateway_id         = try(v.transit_gateway_id, null)
        vpc_endpoint_id            = try(v.vpc_endpoint_id, null)
        vpc_peering_connection_id  = try(v.vpc_peering_connection_id, null)
      }
    ]
  ])
}

####################################################
# route table
####################################################

# route table

resource "aws_route_table" "this" {
  for_each = { for v in var.route_tables : v.name => v if v.create == true }
  vpc_id   = each.value.vpc_id
  tags = merge(var.tags, each.value.tags,
    {
      Name = each.value.name

    }
  )
}

# associations

resource "aws_route_table_association" "this_subnets_rt" {
  for_each       = { for s in local.subnet_ids : s.subnet_id => s if s.create == true }
  route_table_id = aws_route_table.this[each.value.name].id
  subnet_id      = each.value.subnet_id
}

resource "aws_route_table_association" "existing_subnets_rt" {
  for_each       = { for s in local.subnet_ids : s.subnet_id => s if s.id != null }
  route_table_id = data.aws_route_table.existing[each.value.id].id
  subnet_id      = each.value.subnet_id
}

resource "aws_route_table_association" "gateway_rt" {
  for_each       = { for v in var.route_tables : v.name => v if v.gateway_id != null }
  route_table_id = each.value.id
  gateway_id     = each.value.gateway_id
}

####################################################
# routes
####################################################

# ipv4

resource "aws_route" "routes_ipv4" {
  for_each = { for v in local.routes_ipv4 : v.destination_cidr_block => v }

  route_table_id             = each.value.route_table_id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id

  carrier_gateway_id        = each.value.carrier_gateway_id
  core_network_arn          = each.value.core_network_arn
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  local_gateway_id          = each.value.local_gateway_id
  network_interface_id      = each.value.network_interface_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id

  depends_on = [
    aws_route_table.this,
  ]
}

# ipv6

resource "aws_route" "routes_ipv6" {
  for_each = { for v in local.routes_ipv6 : v.destination_ipv6_cidr_block => v }

  route_table_id              = each.value.route_table_id
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block
  destination_prefix_list_id  = each.value.destination_prefix_list_id

  carrier_gateway_id        = each.value.carrier_gateway_id
  core_network_arn          = each.value.core_network_arn
  egress_only_gateway_id    = each.value.egress_only_gateway_id
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  local_gateway_id          = each.value.local_gateway_id
  network_interface_id      = each.value.network_interface_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id

  depends_on = [
    aws_route_table.this,
  ]
}
