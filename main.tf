
data "google_client_config" "default" {  
}

data "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = "us-central1-c"
  # depends_on = [module.gke]
}

provider "google" {
  # credentials = file("/mnt/c/Users/jackyli/Downloads/able-scope-413414-d1f3a6012760.json")
  project = "able-scope-413414"
  region  = "us-central1"
  zone    = "us-central1-c"
}
provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"  
  token                  = data.google_client_config.default.access_token    
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  # client_key             = base64decode(data.google_container_cluster.primary.master_auth.0.client_key)
  # client_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.client_certificate)
}

/*provider "helm" {
  kubernetes {
    # config_path = "~/.kube/config"
    # host                   = "https://${module.gke.endpoint}"
    host  = "https://${data.google_container_cluster.update.endpoint}"
    token                  = data.google_client_config.update.access_token
    # cluster_ca_certificate   = base64decode(module.gke.ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["container", "clusters", "get-credentials", var.cluster_name, "--zone", "us-central1", "--project", var.project_id]
      # args=[]
      # command="gke-gloud-auth-plugin"
      command     = "gcloud"
    }
    cluster_ca_certificate = base64decode(data.google_container_cluster.update.master_auth[0].cluster_ca_certificate)
    client_key             = base64decode(data.google_container_cluster.update.master_auth.0.client_key)
    client_certificate = base64decode(data.google_container_cluster.update.master_auth.0.client_certificate)
  }
}*/
# ----------------------------------------------------------------------------------------
# Read a Kubernetes config file
data "local_file" "yaml_file" {
  filename = "https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml"
}

# Parse the Kubernetes config file
data "yamldecode" "kubernetes_config" {
  input = data.local_file.yaml_file.content
}

# Create Kubernetes resource with the manifest
resource "kubernetes_manifest" "my_resource" {
  manifest = data.yamldecode.kubernetes_config
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "selfsigned-cluster-issuer"
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

/*module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  # depends_on   = [module.gke]
  project_id   = var.project_id  
  location     = module.gke.location
  cluster_name = module.gke.name
  
  
}
resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig"
  depends_on = [module.gke_auth]
}
*/



