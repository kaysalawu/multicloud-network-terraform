
############################################
# data
############################################

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

data "aws_route53_zone" "public_bastion" {
  count        = var.bastion_config.enable && var.bastion_config.public_dns_zone_name != null ? 1 : 0
  name         = "${var.bastion_config.public_dns_zone_name}."
  private_zone = false
}

data "aws_route53_zone" "private" {
  count        = var.private_dns_config.zone_name != null ? 1 : 0
  name         = var.private_dns_config.zone_name
  private_zone = true
  depends_on = [
    aws_vpc.this
  ]
}
