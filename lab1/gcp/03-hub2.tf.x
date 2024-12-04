
####################################################
# network
####################################################

module "hub2_vpc" {
  source     = "./modules/net-vpc"
  project_id = var.project_id
  name       = "${local.hub2_prefix}vpc"
  subnets    = local.hub2_subnets_list

  ipv6_config = {
    enable_ula_internal = true
  }
}

####################################################
# nat
####################################################

module "hub2_nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v34.1.0"
  project_id     = var.project_id
  region         = local.hub2_region
  name           = "${local.hub2_prefix}nat"
  router_network = module.hub2_vpc.self_link
  router_create  = true

  config_source_subnetworks = {
    all = false
    subnetworks = [for s in local.hub2_subnets_list : {
      self_link        = module.hub2_vpc.subnet_self_links["${s.region}/${s.name}"]
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

module "hub2_vpc_firewall" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.1.0"
  project_id = var.project_id
  network    = module.hub2_vpc.name

  egress_rules = {
    "${local.hub2_prefix}allow-egress-smtp" = {
      priority           = 900
      description        = "block smtp"
      destination_ranges = ["0.0.0.0/0", ]
      rules              = [{ protocol = "tcp", ports = [25, ] }]
    }
    "${local.hub2_prefix}allow-egress-all" = {
      priority           = 1000
      deny               = false
      description        = "allow egress"
      destination_ranges = ["0.0.0.0/0", ]
      rules              = [{ protocol = "all", ports = [] }]
    }
  }
  ingress_rules = {
    "${local.hub2_prefix}allow-ingress-internal" = {
      priority      = 1000
      description   = "allow internal"
      source_ranges = local.netblocks.internal
      rules         = [{ protocol = "all", ports = [] }]
    }
    "${local.hub2_prefix}allow-ingress-dns" = {
      priority      = 1100
      description   = "allow dns"
      source_ranges = local.netblocks.dns
      rules         = [{ protocol = "all", ports = [] }]
    }
    "${local.hub2_prefix}allow-ingress-ssh" = {
      priority       = 1200
      description    = "allow ingress ssh"
      source_ranges  = ["0.0.0.0/0"]
      rules          = [{ protocol = "tcp", ports = [22] }]
      enable_logging = {}
    }
    "${local.hub2_prefix}allow-ingress-iap" = {
      priority       = 1300
      description    = "allow ingress iap"
      source_ranges  = local.netblocks.iap
      rules          = [{ protocol = "all", ports = [] }]
      enable_logging = {}
    }
    "${local.hub2_prefix}allow-ingress-dns-proxy" = {
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

module "hub2_vm" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "${local.hub2_prefix}vm"
  zone       = "${local.hub2_region}-b"
  tags       = [local.tag_ssh, local.tag_http]

  network_interfaces = [{
    network    = module.hub2_vpc.self_link
    subnetwork = module.hub2_vpc.subnet_self_links["${local.hub2_region}/hub2-main"]
    addresses  = { internal = local.hub2_vm_addr }
  }]
  service_account = {
    email  = module.hub2_sa.email
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
  hub2_files = {
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}
