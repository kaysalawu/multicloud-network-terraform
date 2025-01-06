
# netblocks

data "google_netblock_ip_ranges" "dns_forwarders" { range_type = "dns-forwarders" }
data "google_netblock_ip_ranges" "private_googleapis" { range_type = "private-googleapis" }
data "google_netblock_ip_ranges" "restricted_googleapis" { range_type = "restricted-googleapis" }
data "google_netblock_ip_ranges" "health_checkers" { range_type = "health-checkers" }
data "google_netblock_ip_ranges" "iap_forwarders" { range_type = "iap-forwarders" }

######################################################
# common
######################################################

locals {
  supernet      = "10.0.0.0/8"
  supernet6     = "fd20::/20"
  cloud_domain  = "g.corp"
  onprem_domain = "corp"
  psk           = "Password123"
  tag_gfe       = "gfe"
  tag_dns       = "dns"
  tag_ssh       = "ssh"
  tag_http      = "http-server"
  tag_https     = "https-server"
  region1       = "europe-west2"

  private_prefixes = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "100.64.0.0/10",
  ]
  private_prefixes_ipv6 = [
    "fd20::/20",
  ]

  netblocks = {
    dns = data.google_netblock_ip_ranges.dns_forwarders.cidr_blocks_ipv4
    gfe = concat(
      data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4,
      ["34.96.0.0/20", "34.127.192.0/18", ]
    )
    iap      = data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4
    internal = local.private_prefixes
  }

  netblocks_ipv6 = {
    gfe      = ["2600:2d00:1:b029::/64", "2600:2d00:1:1::/64", "2600:1901:8001::/48", ]
    internal = local.private_prefixes_ipv6
  }

  bgp_range1  = "169.254.101.0/30"
  bgp_range2  = "169.254.102.0/30"
  bgp_range3  = "169.254.103.0/30"
  bgp_range4  = "169.254.104.0/30"
  bgp_range5  = "169.254.105.0/30"
  bgp_range6  = "169.254.106.0/30"
  bgp_range7  = "169.254.107.0/30"
  bgp_range8  = "169.254.108.0/30"
  bgp_range9  = "169.254.109.0/30"
  bgp_range10 = "169.254.110.0/30"

  bgp_range1_ipv6 = "2600:2d00:0:2::/64"
  bgp_range2_ipv6 = "2600:2d00:0:3::/64"

  uhc_config       = { host = "probe.${local.cloud_domain}", request_path = "healthz", response = "OK" }
  uhc_pan_config   = { host = "google-hc-host" }
  svc_web          = { name = "http", port = 80 }
  svc_juice        = { name = "http3000", port = 3000 }
  svc_grpc         = { name = "grpc", port = 50051 }
  flow_logs_config = { flow_sampling = 0.5, aggregation_interval = "INTERVAL_10_MIN" }
}

resource "random_id" "random" {
  byte_length = 2
}

######################################################
# on-premises
######################################################

# customer1
#--------------------------------

locals {
  customer1_prefix   = var.prefix == "" ? "customer1-" : join("-", [var.prefix, "customer1-"])
  customer1_asn      = "65010"
  customer1_region   = local.region1
  customer1_supernet = "10.10.0.0/16"
  customer1_domain   = "customer1"
  customer1_dns_zone = "${local.customer1_domain}.${local.onprem_domain}"

  customer1_subnets_list = [for k, v in local.customer1_subnets : merge({ name = k }, v)]
  customer1_subnets = {
    customer1-main = { region = local.customer1_region, ip_cidr_range = "10.10.1.0/24", ipv6 = {} }
  }
  customer1_gw_addr        = cidrhost(local.customer1_subnets["customer1-main"].ip_cidr_range, 1)
  customer1_router_addr    = cidrhost(local.customer1_subnets["customer1-main"].ip_cidr_range, 2)
  customer1_ns_addr        = cidrhost(local.customer1_subnets["customer1-main"].ip_cidr_range, 5)
  customer1_vm_addr        = cidrhost(local.customer1_subnets["customer1-main"].ip_cidr_range, 9)
  customer1_router_lo_addr = "1.1.1.1"
  customer1_vm_dns_prefix  = "vm"
  customer1_vm_fqdn        = "${local.customer1_vm_dns_prefix}.${local.customer1_dns_zone}"
}

# customer2
#--------------------------------

locals {
  customer2_prefix   = var.prefix == "" ? "customer2-" : join("-", [var.prefix, "customer2-"])
  customer2_asn      = "65020"
  customer2_region   = local.region1
  customer2_supernet = "10.20.0.0/16"
  customer2_domain   = "customer2"
  customer2_vm_dns   = "vm"
  customer2_dns_zone = "${local.customer2_domain}.${local.onprem_domain}"

  customer2_subnets_list = [for k, v in local.customer2_subnets : merge({ name = k }, v)]
  customer2_subnets = {
    customer2-main = { region = local.customer2_region, ip_cidr_range = "10.20.1.0/24", ipv6 = {} }
  }
  customer2_gw_addr       = cidrhost(local.customer2_subnets["customer2-main"].ip_cidr_range, 1)
  customer2_router_addr   = cidrhost(local.customer2_subnets["customer2-main"].ip_cidr_range, 2)
  customer2_ns_addr       = cidrhost(local.customer2_subnets["customer2-main"].ip_cidr_range, 5)
  customer2_vm_addr       = cidrhost(local.customer2_subnets["customer2-main"].ip_cidr_range, 9)
  customer2_vm_dns_prefix = "vm"
  customer2_vm_fqdn       = "${local.customer2_vm_dns_prefix}.${local.customer2_dns_zone}"
}

# customer3
#--------------------------------

locals {
  customer3_prefix   = var.prefix == "" ? "customer3-" : join("-", [var.prefix, "customer3-"])
  customer3_asn      = "65030"
  customer3_region   = local.region1
  customer3_supernet = "10.30.0.0/16"
  customer3_domain   = "customer3"
  customer3_vm_dns   = "vm"
  customer3_dns_zone = "${local.customer3_domain}.${local.onprem_domain}"

  customer3_subnets_list = [for k, v in local.customer3_subnets : merge({ name = k }, v)]
  customer3_subnets = {
    customer3-main = { region = local.customer3_region, ip_cidr_range = "10.30.1.0/24", ipv6 = {} }
  }
  customer3_gw_addr       = cidrhost(local.customer3_subnets["customer3-main"].ip_cidr_range, 1)
  customer3_router_addr   = cidrhost(local.customer3_subnets["customer3-main"].ip_cidr_range, 2)
  customer3_ns_addr       = cidrhost(local.customer3_subnets["customer3-main"].ip_cidr_range, 5)
  customer3_vm_addr       = cidrhost(local.customer3_subnets["customer3-main"].ip_cidr_range, 9)
  customer3_vm_dns_prefix = "vm"
  customer3_vm_fqdn       = "${local.customer3_vm_dns_prefix}.${local.customer3_dns_zone}"
}

######################################################
# hub1
######################################################

locals {
  hub1_prefix     = var.prefix == "" ? "hub1-" : join("-", [var.prefix, "hub1-"])
  hub1_region     = local.region1
  hub1_vpn_cr_asn = "65100"
  hub1_domain     = "hub1"
  hub1_dns_zone   = "${local.hub1_domain}.${local.cloud_domain}"
  hub1_supernet   = "10.1.0.0/16"

  hub1_subnets_list             = [for k, v in local.hub1_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == null]
  hub1_subnets_private_nat_list = [for k, v in local.hub1_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == "PRIVATE_NAT"]
  hub1_subnets_proxy_only_list  = [for k, v in local.hub1_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == "REGIONAL_MANAGED_PROXY"]
  hub1_subnets_psc_list         = [for k, v in local.hub1_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == "PRIVATE_SERVICE_CONNECT"]

  hub1_subnets = {
    hub1-main         = { region = local.hub1_region, ip_cidr_range = "10.1.1.0/24", ipv6 = {}, enable_private_access = true, flow_logs_config = local.flow_logs_config, }
    hub1-gke          = { region = local.hub1_region, ip_cidr_range = "10.1.2.0/24", ipv6 = {}, enable_private_access = true, secondary_ip_ranges = { pod = "100.96.16.0/20", svc = "100.96.32.0/20" } }
    hub1-reg-proxy    = { region = local.hub1_region, ip_cidr_range = "10.1.3.0/24", ipv6 = {}, enable_private_access = false, purpose = "REGIONAL_MANAGED_PROXY", role = "ACTIVE" }
    hub1-psc-ilb-nat  = { region = local.hub1_region, ip_cidr_range = "10.1.4.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub1-psc-ilb-nat6 = { region = local.hub1_region, ip_cidr_range = "10.1.5.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub1-psc-nlb-nat  = { region = local.hub1_region, ip_cidr_range = "10.1.6.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub1-psc-nlb-nat6 = { region = local.hub1_region, ip_cidr_range = "10.1.7.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub1-psc-alb-nat  = { region = local.hub1_region, ip_cidr_range = "10.1.8.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub1-psc-alb-nat6 = { region = local.hub1_region, ip_cidr_range = "10.1.9.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
  }

  # prefixes
  hub1_gke_master_cidr1 = "172.16.11.0/28"
  hub1_gke_master_cidr2 = "172.16.11.16/28"

  hub1_main_default_gw = cidrhost(local.hub1_subnets["hub1-main"].ip_cidr_range, 1)
  hub1_vm_addr         = cidrhost(local.hub1_subnets["hub1-main"].ip_cidr_range, 9)
  hub1_ilb_addr        = cidrhost(local.hub1_subnets["hub1-main"].ip_cidr_range, 70)
  hub1_nlb_addr        = cidrhost(local.hub1_subnets["hub1-main"].ip_cidr_range, 80)
  hub1_alb_addr        = cidrhost(local.hub1_subnets["hub1-main"].ip_cidr_range, 90)

  # psc/api
  hub1_psc_api_fr_range    = "10.1.0.0/24"                            # vip range
  hub1_psc_api_all_fr_name = "${var.prefix}huball"                    # all-apis forwarding rule name
  hub1_psc_api_sec_fr_name = "${var.prefix}hubsec"                    # vpc-sc forwarding rule name
  hub1_psc_api_all_fr_addr = cidrhost(local.hub1_psc_api_fr_range, 1) # all-apis forwarding rule vip
  hub1_psc_api_sec_fr_addr = cidrhost(local.hub1_psc_api_fr_range, 2) # vpc-sc forwarding rule vip

  hub1_vm_dns_prefix  = "vm"
  hub1_ilb_dns_prefix = "ilb"
  hub1_nlb_dns_prefix = "nlb"
  hub1_alb_dns_prefix = "alb"
  hub1_vm_fqdn        = "${local.hub1_vm_dns_prefix}.${local.hub1_dns_zone}"
  hub1_ilb_fqdn       = "${local.hub1_ilb_dns_prefix}.${local.hub1_dns_zone}"
  hub1_nlb_fqdn       = "${local.hub1_nlb_dns_prefix}.${local.hub1_dns_zone}"
  hub1_alb_fqdn       = "${local.hub1_alb_dns_prefix}.${local.hub1_dns_zone}"
}

######################################################
# hub2
######################################################

locals {
  hub2_prefix     = var.prefix == "" ? "hub2-" : join("-", [var.prefix, "hub2-"])
  hub2_region     = local.region1
  hub2_vpn_cr_asn = "65200"
  hub2_domain     = "hub2"
  hub2_dns_zone   = "${local.hub2_domain}.${local.cloud_domain}"
  hub2_supernet   = "10.2.0.0/16"

  hub2_subnets_list             = [for k, v in local.hub2_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == null]
  hub2_subnets_private_nat_list = [for k, v in local.hub2_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == "PRIVATE_NAT"]
  hub2_subnets_proxy_only_list  = [for k, v in local.hub2_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == "REGIONAL_MANAGED_PROXY"]
  hub2_subnets_psc_list         = [for k, v in local.hub2_subnets : merge({ name = k }, v) if lookup(v, "purpose", null) == "PRIVATE_SERVICE_CONNECT"]

  hub2_subnets = {
    hub2-main         = { region = local.hub2_region, ip_cidr_range = "10.2.1.0/24", ipv6 = {}, enable_private_access = true, flow_logs_config = local.flow_logs_config, }
    hub2-gke          = { region = local.hub2_region, ip_cidr_range = "10.2.2.0/24", ipv6 = {}, enable_private_access = true, secondary_ip_ranges = { pod = "100.96.48.0/20", svc = "100.96.64.0/20" } }
    hub2-reg-proxy    = { region = local.hub2_region, ip_cidr_range = "10.2.3.0/24", ipv6 = {}, enable_private_access = false, purpose = "REGIONAL_MANAGED_PROXY", role = "ACTIVE" }
    hub2-psc-ilb-nat  = { region = local.hub2_region, ip_cidr_range = "10.2.4.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub2-psc-ilb-nat6 = { region = local.hub2_region, ip_cidr_range = "10.2.5.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub2-psc-nlb-nat  = { region = local.hub2_region, ip_cidr_range = "10.2.6.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub2-psc-nlb-nat6 = { region = local.hub2_region, ip_cidr_range = "10.2.7.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub2-psc-alb-nat  = { region = local.hub2_region, ip_cidr_range = "10.2.8.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
    hub2-psc-alb-nat6 = { region = local.hub2_region, ip_cidr_range = "10.2.9.0/24", ipv6 = {}, enable_private_access = false, purpose = "PRIVATE_SERVICE_CONNECT" }
  }

  # prefixes
  hub2_gke_master_cidr1 = "172.16.22.0/28"
  hub2_gke_master_cidr2 = "172.16.22.16/28"

  hub2_main_default_gw = cidrhost(local.hub2_subnets["hub2-main"].ip_cidr_range, 1)
  hub2_vm_addr         = cidrhost(local.hub2_subnets["hub2-main"].ip_cidr_range, 9)
  hub2_ilb_addr        = cidrhost(local.hub2_subnets["hub2-main"].ip_cidr_range, 70)
  hub2_nlb_addr        = cidrhost(local.hub2_subnets["hub2-main"].ip_cidr_range, 80)
  hub2_alb_addr        = cidrhost(local.hub2_subnets["hub2-main"].ip_cidr_range, 90)

  # psc/api
  hub2_psc_api_fr_range    = "10.2.0.0/24"                            # vip range
  hub2_psc_api_all_fr_name = "${var.prefix}huball"                    # all-apis forwarding rule name
  hub2_psc_api_sec_fr_name = "${var.prefix}hubsec"                    # vpc-sc forwarding rule name
  hub2_psc_api_all_fr_addr = cidrhost(local.hub2_psc_api_fr_range, 1) # all-apis forwarding rule vip
  hub2_psc_api_sec_fr_addr = cidrhost(local.hub2_psc_api_fr_range, 2) # vpc-sc forwarding rule vip

  hub2_vm_dns_prefix  = "vm"
  hub2_ilb_dns_prefix = "ilb"
  hub2_nlb_dns_prefix = "nlb"
  hub2_alb_dns_prefix = "alb"
  hub2_vm_fqdn        = "${local.hub2_vm_dns_prefix}.${local.hub2_dns_zone}"
  hub2_ilb_fqdn       = "${local.hub2_ilb_dns_prefix}.${local.hub2_dns_zone}"
  hub2_nlb_fqdn       = "${local.hub2_nlb_dns_prefix}.${local.hub2_dns_zone}"
  hub2_alb_fqdn       = "${local.hub2_alb_dns_prefix}.${local.hub2_dns_zone}"
}

