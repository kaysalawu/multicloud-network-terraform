
####################################################
# interface
####################################################

# interface

resource "aws_network_interface" "this" {
  for_each          = { for interface in var.interfaces : interface.name => interface }
  subnet_id         = each.value.subnet_id
  private_ips       = each.value.private_ips != [] ? each.value.private_ips : null
  ipv6_addresses    = each.value.ipv6_addresses != [] ? each.value.ipv6_addresses : null
  security_groups   = each.value.security_group_ids
  source_dest_check = each.value.source_dest_check

  tags = merge(var.tags,
    {
      Name = each.value.name
    }
  )
}

# elastic ip

resource "aws_eip" "this" {
  for_each = { for interface in var.interfaces : interface.name => interface if interface.create_eip && interface.eip_tag_name == null }
  domain   = "vpc"

  tags = merge(var.tags,
    {
      Name = each.value.name
    }
  )
  depends_on = [
    data.aws_eip.this,
  ]
}

resource "aws_eip_association" "new" {
  for_each             = { for interface in var.interfaces : interface.name => interface if interface.create_eip && interface.eip_tag_name == null }
  instance_id          = aws_network_interface.this[each.key].id == null ? aws_instance.this.id : null
  network_interface_id = aws_network_interface.this[each.key].id
  private_ip_address   = length(each.value.private_ips) > 0 ? each.value.private_ips[0] : null
  allocation_id        = aws_eip.this[each.key].id
}

resource "aws_eip_association" "existing" {
  for_each             = { for interface in var.interfaces : interface.name => interface if interface.eip_tag_name != null }
  instance_id          = aws_network_interface.this[each.key].id == null ? aws_instance.this.id : null
  network_interface_id = aws_network_interface.this[each.key].id
  private_ip_address   = length(each.value.private_ips) > 0 ? each.value.private_ips[0] : null
  allocation_id        = data.aws_eip.this[each.key].id
  public_ip            = each.value.eip_tag_name != null ? each.value.public_ip : null
  depends_on = [
    aws_eip.this,
  ]
}

####################################################
# instance
####################################################

# instance

resource "aws_instance" "this" {
  instance_type        = var.instance_type
  availability_zone    = var.availability_zone
  ami                  = var.ami
  key_name             = var.key_name
  iam_instance_profile = var.iam_instance_profile
  source_dest_check    = var.source_dest_check
  user_data            = var.user_data

  dynamic "network_interface" {
    for_each = { for index, interface in var.interfaces : interface.name => merge(interface, { device_index = index }) }
    content {
      device_index         = network_interface.value.device_index
      network_interface_id = aws_network_interface.this[network_interface.key].id
    }
  }

  metadata_options {
    instance_metadata_tags = var.instance_metadata_tags
  }

  tags = merge(var.tags,
    {
      Name = var.name
    }
  )
}

####################################################
# dns record
####################################################

# private

resource "aws_route53_record" "this" {
  for_each = { for interface in var.interfaces : interface.name => interface if interface.dns_config.zone_name != null && !interface.dns_config.public }
  zone_id  = data.aws_route53_zone.private[each.key].id
  name     = each.value.dns_config.name != null ? each.value.dns_config.name : aws_instance.this.tags.Name
  type     = each.value.dns_config.type
  ttl      = each.value.dns_config.ttl
  records  = [aws_instance.this.private_ip, ]

  depends_on = [
    aws_instance.this,
  ]
  lifecycle {
    ignore_changes = [
      zone_id,
    ]
  }
}

# public

resource "aws_route53_record" "public" {
  for_each = { for interface in var.interfaces : interface.name => interface if interface.dns_config.zone_name != null && interface.dns_config.public }
  zone_id  = data.aws_route53_zone.public[each.key].id
  name     = each.value.dns_config.name != null ? each.value.dns_config.name : aws_instance.this.tags.Name
  type     = each.value.dns_config.type
  ttl      = each.value.dns_config.ttl
  records  = [aws_instance.this.public_ip, ]

  lifecycle {
    ignore_changes = [
      zone_id,
    ]
  }
  depends_on = [
    aws_network_interface.this,
    aws_instance.this,
  ]
}


