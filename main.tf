data "google_client_config" "default" {
}


provider "google" {
  credentials = file("/mnt/c/Users/jackyli/Downloads/able-scope-413414-d1f3a6012760.json")

  project = "able-scope-413414"
  region  = "us-central1"
  zone    = "us-central1-c"
}
provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 7.5"

  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name           = var.subnetwork
      subnet_ip             = "10.0.0.0/20"
      subnet_region         = var.region
      subnet_private_access = "false"
    },
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "172.20.0.0/20"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "172.18.0.0/18"
      },
    ]
  }
}

data "google_compute_subnetwork" "subnetwork" {
  name       = var.subnetwork
  project    = var.project_id
  region     = var.region
  depends_on = [module.gcp-network]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 30.0"

  project_id = var.project_id
  name       = var.cluster_name
  regional   = false
  region     = var.region
  zones      = slice(var.zones, 0, 1)

  network                 = module.gcp-network.network_name
  subnetwork              = module.gcp-network.subnets_names[0]
  ip_range_pods           = var.ip_range_pods_name
  ip_range_services       = var.ip_range_services_name
  create_service_account  = false
  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "10.0.0.0/20"
  deletion_protection     = false
  firewall_inbound_ports     = ["30443", "22"]
  master_authorized_networks = [
    {
      cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
      display_name = "VPC"
    },
  ]
}


