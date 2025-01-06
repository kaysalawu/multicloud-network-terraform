
####################################################
# lab
####################################################

locals {
}

data "google_client_config" "current" {}

####################################################
# common resources
####################################################

# artifacts registry

resource "google_artifact_registry_repository" "hub1_repo" {
  project       = var.project_id
  location      = local.hub1_region
  repository_id = "${local.hub1_prefix}eu-repo"
  format        = "DOCKER"
}

####################################################
# vm startup scripts
####################################################

locals {
  init_dir = "/var/lib/gcp"
  vm_script_targets_region1 = [
    # { name = "customer1-vm     ", host = local.customer1_vm_fqdn, ipv4 = local.customer1_vm_addr, probe = true, ping = true },
    # { name = "hub1-vm    ", host = local.hub1_vm_fqdn, ipv4 = local.hub1_vm_addr, probe = true, ping = true },
    # { name = "hub1-ilb   ", host = local.hub1_ilb_fqdn, ipv4 = local.hub1_ilb_addr, },
    # { name = "hub1-nlb   ", host = local.hub1_nlb_fqdn, ipv4 = local.hub1_nlb_addr, ipv6 = false },
    # { name = "hub1-alb   ", host = local.hub1_alb_fqdn, ipv4 = local.hub1_alb_addr, ipv6 = false },
  ]
  vm_script_targets_misc = [
    # { name = "hub1-geo-ilb", host = local.hub1_geo_ilb_fqdn },
    # { name = "internet", host = "icanhazip.com", probe = true },
    # { name = "www", host = "www.googleapis.com", path = "/generate_204", probe = true },
    # { name = "storage", host = "storage.googleapis.com", path = "/generate_204", probe = true },
    # { name = "hub1-psc-https", host = local.hub1_psc_https_ctrl_run_dns, path = "/generate_204" },
    # { name = "hub1-run", host = local.hub1_run_httpbin_host, probe = true, path = "/generate_204" },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  vm_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  vm_init_files = {
    # "${local.init_dir}/fastapi/docker-compose-http-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("./scripts/init/fastapi/docker-compose-http-80.yml", {}) }
    # "${local.init_dir}/fastapi/docker-compose-http-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("./scripts/init/fastapi/docker-compose-http-8080.yml", {}) }
    # "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("./scripts/init/fastapi/app/app/Dockerfile", {}) }
    # "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("./scripts/init/fastapi/app/app/_app.py", {}) }
    # "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("./scripts/init/fastapi/app/app/main.py", {}) }
    # "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("./scripts/init/fastapi/app/app/requirements.txt", {}) }
  }
  vm_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("scripts/startup.sh", local.vm_init_vars) }
  }
}

module "vm_cloud_init" {
  source = "./modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files
  )
  run_commands = [
    ". ${local.init_dir}/init/startup.sh",
    # "HOSTNAME=$(hostname) docker compose -f ${local.init_dir}/fastapi/docker-compose-http-80.yml up -d",
    # "HOSTNAME=$(hostname) docker compose -f ${local.init_dir}/fastapi/docker-compose-http-8080.yml up -d",
  ]
}

############################################
# addresses
############################################

# customer1
#---------------------------------

# addresses

# service account

module "customer1_sa" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id   = var.project_id
  name         = trimsuffix("${local.customer1_prefix}sa", "-")
  generate_key = false
  iam_project_roles = {
    (var.project_id) = ["roles/owner", ]
  }
}

# customer2
#---------------------------------

# addresses

# service account

module "customer2_sa" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id   = var.project_id
  name         = trimsuffix("${local.customer2_prefix}sa", "-")
  generate_key = false
  iam_project_roles = {
    (var.project_id) = ["roles/owner", ]
  }
}

# customer3
#---------------------------------

# addresses

# service account

module "customer3_sa" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id   = var.project_id
  name         = trimsuffix("${local.customer3_prefix}sa", "-")
  generate_key = false
  iam_project_roles = {
    (var.project_id) = ["roles/owner", ]
  }
}

############################################
# hub1
############################################

# service account

module "hub1_sa" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id   = var.project_id
  name         = trimsuffix("${local.hub1_prefix}sa", "-")
  generate_key = false
  iam_project_roles = {
    (var.project_id) = ["roles/owner", ]
  }
}

############################################
# hub2
############################################

# service account

module "hub2_sa" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id   = var.project_id
  name         = trimsuffix("${local.hub2_prefix}sa", "-")
  generate_key = false
  iam_project_roles = {
    (var.project_id) = ["roles/owner", ]
  }
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh"           = local.vm_startup
    "output/startup.sh"          = templatefile("scripts/startup.sh", local.vm_init_vars)
    "output/vm-cloud-config.yml" = module.vm_cloud_init.cloud_config
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}
