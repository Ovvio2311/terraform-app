
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
provider "kubectl" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"  
  token                  = data.google_client_config.default.access_token    
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  load_config_file       = false
  # client_key             = base64decode(data.google_container_cluster.primary.master_auth.0.client_key)
  # client_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.client_certificate)
}
provider "helm" {
  kubernetes {
    # config_path = "~/.kube/config"
    # host                   = "https://${module.gke.endpoint}"
    host  = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    # cluster_ca_certificate   = base64decode(module.gke.ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["container", "clusters", "get-credentials", var.cluster_name, "--zone", "us-central1", "--project", var.project_id]
      # args=[]
      # command="gke-gloud-auth-plugin"
      command     = "gcloud"
    }
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
    client_key             = base64decode(data.google_container_cluster.primary.master_auth.0.client_key)
    client_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.client_certificate)
  }
}
# ----------------------------------------------------------------------------------------
# create namespace
resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

data "http" "cert-manager" {
  # count = var.enable_argocd ? 1 : 0
  url   = "https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml"
}

resource "kubectl_manifest" "cert-manager-crds" {
  # count     = var.enable_argocd ? 1 : 0
  yaml_body = data.http.cert-manager.response_body
}


/*resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.7.1"

  namespace        = "cert-manager"
  create_namespace = true

  #values = [file("cert-manager-values.yaml")]

  set {
    name  = "installCRDs"
    value = "true"
  }

}*/
/*# Read a Kubernetes config file
data "local_file" "yaml_file" {
  filename  = file("cert-manager.yaml")
}*/



# Create Kubernetes resource with the manifest

resource "kubectl_manifest" "clusterissuer"{
  depends_on = [kubectl_manifest.cert-manager-crds]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
YAML
}



/*resource "kubectl_manifest" "clusterissuer" {
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
}*/

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



