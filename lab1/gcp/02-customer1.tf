
####################################################
# network
####################################################

module "customer1_vpc" {
  source     = "./modules/net-vpc"
  project_id = var.project_id
  name       = "${local.customer1_prefix}vpc"
  subnets    = local.customer1_subnets_list

  ipv6_config = {
    enable_ula_internal = true
  }
}

####################################################
# nat
####################################################

module "customer1_nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v34.1.0"
  project_id     = var.project_id
  region         = local.customer1_region
  name           = "${local.customer1_prefix}nat"
  router_network = module.customer1_vpc.self_link
  router_create  = true

  config_source_subnetworks = {
    all = false
    subnetworks = [for s in local.customer1_subnets_list : {
      self_link        = module.customer1_vpc.subnet_self_links["${s.region}/${s.name}"]
      all_ranges       = false
      primary_range    = true
      secondary_ranges = contains(keys(try(s.secondary_ip_ranges, {})), "pods") ? ["pods"] : null
    }]
  }
}

####################################################
# firewall
####################################################

# vpc

module "customer1_vpc_firewall" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.1.0"
  project_id = var.project_id
  network    = module.customer1_vpc.name

  egress_rules = {
    "${local.customer1_prefix}allow-egress-smtp" = {
      priority           = 900
      description        = "block smtp"
      destination_ranges = ["0.0.0.0/0", ]
      rules              = [{ protocol = "tcp", ports = [25, ] }]
    }
    "${local.customer1_prefix}allow-egress-all" = {
      priority           = 1000
      deny               = false
      description        = "allow egress"
      destination_ranges = ["0.0.0.0/0", ]
      rules              = [{ protocol = "all", ports = [] }]
    }
  }
  ingress_rules = {
    "${local.customer1_prefix}allow-ingress-internal" = {
      priority      = 1000
      description   = "allow internal"
      source_ranges = local.netblocks.internal
      rules         = [{ protocol = "all", ports = [] }]
    }
    "${local.customer1_prefix}allow-ingress-dns" = {
      priority      = 1100
      description   = "allow dns"
      source_ranges = local.netblocks.dns
      rules         = [{ protocol = "all", ports = [] }]
    }
    "${local.customer1_prefix}allow-ingress-ssh" = {
      priority       = 1200
      description    = "allow ingress ssh"
      source_ranges  = ["0.0.0.0/0"]
      rules          = [{ protocol = "tcp", ports = [22] }]
      enable_logging = {}
    }
    "${local.customer1_prefix}allow-ingress-iap" = {
      priority       = 1300
      description    = "allow ingress iap"
      source_ranges  = local.netblocks.iap
      rules          = [{ protocol = "all", ports = [] }]
      enable_logging = {}
    }
    "${local.customer1_prefix}allow-ingress-dns-proxy" = {
      priority      = 1400
      description   = "allow dns egress proxy"
      source_ranges = local.netblocks.dns
      targets       = [local.tag_dns]
      rules         = [{ protocol = "all", ports = [] }]
    }
  }
}

####################################################
# cloud dns
####################################################


####################################################
# workload
####################################################

# app

module "customer1_vm" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "${local.customer1_prefix}vm"
  zone       = "${local.customer1_region}-b"
  tags       = [local.tag_ssh, local.tag_http]

  network_interfaces = [{
    network    = module.customer1_vpc.self_link
    subnetwork = module.customer1_vpc.subnet_self_links["${local.customer1_region}/customer1-main"]
    addresses  = { internal = local.customer1_vm_addr }
  }]
  service_account = {
    email  = module.customer1_sa.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    user-data = module.vm_cloud_init.cloud_config
  }
}

####################################################
# output files
####################################################

locals {
  customer1_files = {
  }
}

resource "local_file" "customer1_files" {
  for_each = local.customer1_files
  filename = each.key
  content  = each.value
}
