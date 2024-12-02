
locals {
  prefix       = var.prefix == "" ? "" : format("%s-", var.prefix)
  my_public_ip = chomp(data.http.my_public_ip.response_body)
}

data "http" "my_public_ip" {
  url = "http://ipv4.icanhazip.com"
}

####################################################
# key pairs
####################################################

resource "aws_key_pair" "this" {
  key_name   = "${local.prefix}kp-${var.region}"
  public_key = file(var.public_key_path)
}

####################################################
# ipam
####################################################

# ipam

resource "aws_vpc_ipam" "this" {
  enable_private_gua = var.ipam_enable_private_gua
  tier               = var.ipam_tier
  description        = var.region

  operating_regions {
    region_name = var.region
  }
  tags = merge(
    { Name = "${local.prefix}ipam" },
    var.tags
  )
}

# scopes

resource "aws_vpc_ipam_pool" "ipam_scope_id_ipv4" {
  address_family = "ipv4"
  description    = "ipv4: ${var.region}"
  ipam_scope_id  = aws_vpc_ipam.this.private_default_scope_id
  locale         = var.region
  tags = merge(
    { Name = "ipv4-${var.region}" },
    var.tags
  )
}

resource "aws_vpc_ipam_pool" "ipam_scope_id_ipv6" {
  address_family = "ipv6"
  description    = "ipv6: ${var.region}"
  ipam_scope_id  = aws_vpc_ipam.this.private_default_scope_id
  locale         = var.region
  tags = {
    Name = "ipv6-${var.region}"
  }
}

####################################################
# iam
####################################################

# policy allowing ec2 to assume role

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# policy granting full access

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["*"]
    resources = ["*"]
    effect    = "Allow"
  }
}

# iam role for ec2 with assume role permissions

resource "aws_iam_role" "ec2_iam_role" {
  name               = "${local.prefix}ec2-iam-role-${var.region}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

# attach policy to role

resource "aws_iam_role_policy" "s3_iam_policy" {
  name   = "${local.prefix}s3-iam-policy-${var.region}"
  role   = aws_iam_role.ec2_iam_role.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.prefix}ec2-instance-profile-${var.region}"
  role = aws_iam_role.ec2_iam_role.name
}

####################################################
# s3
####################################################

resource "random_id" "bucket" {
  byte_length = 2
}

resource "aws_s3_bucket" "bucket" {
  bucket        = replace(replace(lower("${local.prefix}${var.region}${random_id.bucket.hex}"), "-", ""), "_", "")
  force_destroy = true
  tags          = var.tags
}



