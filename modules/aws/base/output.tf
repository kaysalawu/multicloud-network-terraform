
####################################################
# vpc
####################################################

output "vpc_name" {
  value = aws_vpc.this.tags.Name
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "vpc_ipv6_cidr_block" {
  value = aws_vpc.this.ipv6_cidr_block
}

output "subnet_ids" {
  value = try({ for k, v in aws_subnet.this : k => v.id }, {})
}

####################################################
# security group
####################################################

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "nva_sg_id" {
  value = aws_security_group.nva_sg.id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}

output "elb_sg_id" {
  value = aws_security_group.elb_sg.id
}

####################################################
# bastion
####################################################

output "bastion_id" {
  value = try(module.bastion[0].instance_id, "")
}

output "route_tables" {
  value = try(aws_route_table.this, {})
}

output "route_table_ids" {
  value = try({ for k, v in aws_route_table.this : k => v.id }, {})
}

####################################################
# gateways
####################################################

output "internet_gateway" {
  value = try(aws_internet_gateway.this[0], {})
}

output "internet_gateway_id" {
  value = try(aws_internet_gateway.this[0].id, "")
}

output "nat_gateways" {
  value = try(aws_nat_gateway.natgw, {})
}

output "nat_gateway_ids" {
  value = try({ for k, v in aws_nat_gateway.natgw : k => v.id }, {})
}
