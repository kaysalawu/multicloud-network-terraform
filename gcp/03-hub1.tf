
locals {
  hub1_ingress_namespace = "default"
  hub1_master_authorized_networks = [
    { display_name = "100-64-10", cidr_block = "100.64.0.0/10" },
    { display_name = "all", cidr_block = "0.0.0.0/0" }
  ]
}

####################################################
# network
####################################################

module "hub1_vpc" {
  source     = "./modules/net-vpc"
  project_id = var.project_id
  name       = "${local.hub1_prefix}vpc"
  subnets    = local.hub1_subnets_list

  ipv6_config = {
    enable_ula_internal = true
  }
}

####################################################
# nat
####################################################

module "hub1_nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v34.1.0"
  project_id     = var.project_id
  region         = local.hub1_region
  name           = "${local.hub1_prefix}nat"
  router_network = module.hub1_vpc.self_link
  router_create  = true

  config_source_subnetworks = {
    all = false
    subnetworks = [for s in local.hub1_subnets_list : {
      self_link        = module.hub1_vpc.subnet_self_links["${s.region}/${s.name}"]
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

module "hub1_vpc_firewall" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.1.0"
  project_id = var.project_id
  network    = module.hub1_vpc.name

  egress_rules = {
    "${local.hub1_prefix}allow-egress-smtp" = {
      priority           = 900
      description        = "block smtp"
      destination_ranges = ["0.0.0.0/0", ]
      rules              = [{ protocol = "tcp", ports = [25, ] }]
    }
    "${local.hub1_prefix}allow-egress-all" = {
      priority           = 1000
      deny               = false
      description        = "allow egress"
      destination_ranges = ["0.0.0.0/0", ]
      rules              = [{ protocol = "all", ports = [] }]
    }
  }
  ingress_rules = {
    "${local.hub1_prefix}allow-ingress-internal" = {
      priority      = 1000
      description   = "allow internal"
      source_ranges = local.netblocks.internal
      rules         = [{ protocol = "all", ports = [] }]
    }
    "${local.hub1_prefix}allow-ingress-dns" = {
      priority      = 1100
      description   = "allow dns"
      source_ranges = local.netblocks.dns
      rules         = [{ protocol = "all", ports = [] }]
    }
    "${local.hub1_prefix}allow-ingress-ssh" = {
      priority       = 1200
      description    = "allow ingress ssh"
      source_ranges  = ["0.0.0.0/0"]
      rules          = [{ protocol = "tcp", ports = [22] }]
      enable_logging = {}
    }
    "${local.hub1_prefix}allow-ingress-iap" = {
      priority       = 1300
      description    = "allow ingress iap"
      source_ranges  = local.netblocks.iap
      rules          = [{ protocol = "all", ports = [] }]
      enable_logging = {}
    }
    "${local.hub1_prefix}allow-ingress-dns-proxy" = {
      priority      = 1400
      description   = "allow dns egress proxy"
      source_ranges = local.netblocks.dns
      targets       = [local.tag_dns]
      rules         = [{ protocol = "all", ports = [] }]
    }
  }
}

####################################################
# ingress cluster
####################################################

# cluster

resource "google_container_cluster" "hub1_ingress" {
  project  = var.project_id
  name     = "${local.hub1_prefix}ingress"
  location = "${local.hub1_region}-b"

  default_max_pods_per_node = 110
  remove_default_node_pool  = true
  initial_node_count        = 1

  network           = module.hub1_vpc.self_link
  subnetwork        = module.hub1_vpc.subnet_self_links["${local.hub1_region}/hub1-gke"]
  datapath_provider = "LEGACY_DATAPATH"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod"
    services_secondary_range_name = "svc"
  }

  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = local.hub1_gke_master_cidr1
    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = local.hub1_master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  dns_config {
    cluster_dns        = "CLOUD_DNS"
    cluster_dns_scope  = "CLUSTER_SCOPE"
    cluster_dns_domain = "cluster.local"
  }

  # workload_identity_config {
  #   workload_pool = "${var.project_id}.svc.id.goog"
  # }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      # "POD",
      # "DAEMONSET",
      # "DEPLOYMENT",
      # "WORKLOADS",
    ]
    managed_prometheus {
      enabled = false
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  # lifecycle {
  #   ignore_changes = all
  # }
}

data "google_container_cluster" "hub1_ingress" {
  project  = var.project_id
  name     = google_container_cluster.hub1_ingress.name
  location = google_container_cluster.hub1_ingress.location
}

# node pool
#------------------------------------------

resource "google_container_node_pool" "hub1_ingress" {
  project    = var.project_id
  name       = "${local.hub1_prefix}ingress"
  cluster    = google_container_cluster.hub1_ingress.id
  location   = "${local.hub1_region}-b"
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  node_config {
    machine_type    = "e2-medium"
    disk_size_gb    = "80"
    disk_type       = "pd-ssd"
    preemptible     = true
    service_account = module.hub1_sa.email
    oauth_scopes    = ["cloud-platform"]
    tags            = [local.tag_ssh, ]

    # workload_metadata_config {
    #   mode = "GKE_METADATA"
    # }
  }
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

####################################################
# workload identity
####################################################

# kubernetes provider

provider "kubernetes" {
  alias                  = "hub1"
  host                   = "https://${data.google_container_cluster.hub1_ingress.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.hub1_ingress.master_auth.0.cluster_ca_certificate)
}

# gcp service account

module "hub1_sa_gke" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id = var.project_id
  name       = "${local.hub1_prefix}sa-gke"
  # iam = {
  #   "roles/iam.workloadIdentityUser" = [
  #     "serviceAccount:${var.project_id}.svc.id.goog[${local.hub1_ingress_namespace}/${local.hub1_prefix}sa-gke]"
  #   ]
  # }
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/editor",
    ]
  }
}

# # k8s service account

# resource "kubernetes_service_account" "hub1_sa_gke" {
#   provider = kubernetes.hub1
#   metadata {
#     name      = "ingress-ksa"
#     namespace = local.hub1_ingress_namespace
#     annotations = {
#       "iam.gke.io/gcp-service-account" = module.hub1_sa_gke.email
#     }
#   }
# }

# iam policy binding

# resource "google_project_iam_member" "hub1_ingress_workload_id_role" {
#   service_account_id = module.hub1_sa_gke.id
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[${local.hub1_ingress_namespace}/${local.hub1_prefix}sa-gke]"
# }

####################################################
# output files
####################################################

locals {
  hub1_files = {
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}
