####################################################
# load balancer
####################################################

output "resource" {
  description = "The load balancer we created"
  value       = aws_lb.this[0]
}

output "id" {
  description = "The ID and ARN of the load balancer we created"
  value       = try(aws_lb.this[0].id, null)
}

output "arn" {
  description = "The ID and ARN of the load balancer we created"
  value       = try(aws_lb.this[0].arn, null)
}

output "arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch"
  value       = try(aws_lb.this[0].arn_suffix, null)
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = try(aws_lb.this[0].dns_name, null)
}

output "zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records"
  value       = try(aws_lb.this[0].zone_id, null)
}

####################################################
# listeners
####################################################

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = aws_lb_listener.this
}

####################################################
# target groups
####################################################

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = aws_lb_target_group.this
}

####################################################
# route53 records
####################################################

output "route53_records" {
  description = "The Route53 records created and attached to the load balancer"
  value       = aws_route53_record.this
}

####################################################
# endpoint services
####################################################

output "endpoint_service_id" {
  description = "The ID of the VPC endpoint service we created"
  value       = try(aws_vpc_endpoint_service.this.0.id, null)
}

output "endpoint_service_name" {
  description = "The name of the VPC endpoint service we created"
  value       = try(aws_vpc_endpoint_service.this.0.service_name, null)
}
