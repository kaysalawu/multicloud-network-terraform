
################################################################################
# Transit Gateway
################################################################################

output "arn" {
  description = "EC2 Transit Gateway Amazon Resource Name (ARN)"
  value       = try(aws_ec2_transit_gateway.this[0].arn, "")
}

output "id" {
  description = "EC2 Transit Gateway identifier"
  value       = try(aws_ec2_transit_gateway.this[0].id, "")
}

output "owner_id" {
  description = "Identifier of the AWS account that owns the EC2 Transit Gateway"
  value       = try(aws_ec2_transit_gateway.this[0].owner_id, "")
}

output "association_default_route_table_id" {
  description = "Identifier of the default association route table"
  value       = try(aws_ec2_transit_gateway.this[0].association_default_route_table_id, "")
}

output "propagation_default_route_table_id" {
  description = "Identifier of the default propagation route table"
  value       = try(aws_ec2_transit_gateway.this[0].propagation_default_route_table_id, "")
}

################################################################################
# VPC Attachment
################################################################################

output "vpc_attachment_ids" {
  description = "List of EC2 Transit Gateway VPC Attachment identifiers"
  value       = [for k, v in aws_ec2_transit_gateway_vpc_attachment.this : v.id]
}

output "vpc_attachment" {
  description = "Map of EC2 Transit Gateway VPC Attachment attributes"
  value       = aws_ec2_transit_gateway_vpc_attachment.this
}

################################################################################
# Route Table / Routes
################################################################################

output "route_table_default_association_route_table" {
  description = "Boolean whether this is the default association route table for the EC2 Transit Gateway"
  value       = try(aws_ec2_transit_gateway_route_table.this[0].default_association_route_table, "")
}

output "route_table_default_propagation_route_table" {
  description = "Boolean whether this is the default propagation route table for the EC2 Transit Gateway"
  value       = try(aws_ec2_transit_gateway_route_table.this[0].default_propagation_route_table, "")
}

output "route_table_ids" {
  description = "EC2 Transit Gateway Route Table identifiers"
  value       = { for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id }
}

output "route_ids" {
  description = "List of EC2 Transit Gateway Route Table identifiers"
  value       = { for k, v in aws_ec2_transit_gateway_route.this : k => v.id }
}

output "route_table_association_ids" {
  description = "List of EC2 Transit Gateway Route Table Association identifiers"
  value       = [for k, v in aws_ec2_transit_gateway_route_table_association.this : v.id]
}

output "route_table_association" {
  description = "Map of EC2 Transit Gateway Route Table Association attributes"
  value       = aws_ec2_transit_gateway_route_table_association.this
}

output "route_table_propagation_ids" {
  description = "List of EC2 Transit Gateway Route Table Propagation identifiers"
  value       = [for k, v in aws_ec2_transit_gateway_route_table_propagation.this : v.id]
}

output "route_table_propagation" {
  description = "Map of EC2 Transit Gateway Route Table Propagation attributes"
  value       = aws_ec2_transit_gateway_route_table_propagation.this
}

################################################################################
# Resource Access Manager
################################################################################

output "ram_resource_share_id" {
  description = "The Amazon Resource Name (ARN) of the resource share"
  value       = try(aws_ram_resource_share.this[0].id, "")
}

output "ram_principal_association_id" {
  description = "The Amazon Resource Name (ARN) of the Resource Share and the principal, separated by a comma"
  value       = try(aws_ram_principal_association.this[0].id, "")
}
