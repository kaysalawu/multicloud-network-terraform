
locals {
  external_ingress_ports = ["80", "8080", "443", "3000", ]
}

# TODO: use prefix lists for private prefixes

####################################################
# bastion
####################################################

# security group

resource "aws_security_group" "bastion_sg" {
  name   = "${local.prefix}bastion-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags,
    {
      Name  = "${local.prefix}bastion-sg"
      Scope = "public"
    }
  )
}

# ingress - external (ssh)

resource "aws_security_group_rule" "bastion_ingress_external_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# egress - all

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

####################################################
# ec2
####################################################

# security group

resource "aws_security_group" "ec2_sg" {
  name   = "${local.prefix}ec2-sg"
  vpc_id = aws_vpc.this.id

  tags = {
    Name  = "${local.prefix}ec2-sg"
    Scope = "private"
  }
}

# ingress - internal (all)

resource "aws_security_group_rule" "ec2_ingress_internal_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.private_prefixes_ipv4
  ipv6_cidr_blocks  = var.private_prefixes_ipv6
  security_group_id = aws_security_group.ec2_sg.id
}

# ingress - external (tcp)

resource "aws_security_group_rule" "ingress_external_tcp" {
  for_each          = toset(local.external_ingress_ports)
  type              = "ingress"
  from_port         = 0
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

# egress - all

resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

####################################################
# elb
####################################################

# security group

resource "aws_security_group" "elb_sg" {
  name   = "${local.prefix}elb-sg"
  vpc_id = aws_vpc.this.id

  tags = {
    Name  = "${local.prefix}elb-sg"
    Scope = "private"
  }
}

# ingress - internal (all)

resource "aws_security_group_rule" "elb_ingress_internal_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.private_prefixes_ipv4
  ipv6_cidr_blocks  = var.private_prefixes_ipv6
  security_group_id = aws_security_group.elb_sg.id
}

# ingress - external (tcp)

resource "aws_security_group_rule" "elb_ingress_external_tcp" {
  for_each          = toset(local.external_ingress_ports)
  type              = "ingress"
  from_port         = 0
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.elb_sg.id
}

# egress - all

resource "aws_security_group_rule" "elb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.elb_sg.id
}

####################################################
# nva
####################################################

# security group

resource "aws_security_group" "nva_sg" {
  name   = "${local.prefix}nva-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags,
    {
      Name  = "${local.prefix}nva-sg"
      Scope = "public"
    }
  )
}

# ingress - external (ssh)

resource "aws_security_group_rule" "nva_ingress_external_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

# ingress - external (ike)

resource "aws_security_group_rule" "nva_ingress_external_ike" {
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

# ingress - external (nat-t)

resource "aws_security_group_rule" "nva_ingress_external_nat_t" {
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

# ingress - internal (all)

resource "aws_security_group_rule" "nva_internal_ingress_all" {
  type              = "ingress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = var.private_prefixes_ipv4
  ipv6_cidr_blocks  = var.private_prefixes_ipv6
  security_group_id = aws_security_group.nva_sg.id
}

# egress - all

resource "aws_security_group_rule" "nva_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}
