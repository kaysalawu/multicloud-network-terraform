
output "bucket" {
  value = aws_s3_bucket.bucket
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.ec2_instance_profile
}

output "ipam_id" {
  value = aws_vpc_ipam.this.id
}

output "ipv4_ipam_pool_id" {
  value = aws_vpc_ipam_pool.ipam_scope_id_ipv4.id
}

output "ipv6_ipam_pool_id" {
  value = aws_vpc_ipam_pool.ipam_scope_id_ipv6.id
}

output "key_pair_name" {
  value = aws_key_pair.this.key_name
}

