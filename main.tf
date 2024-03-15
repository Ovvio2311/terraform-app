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
resource "helm_release" "cert-manager" {
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
}

# Create Kubernetes resource with the manifest
resource "kubectl_manifest" "clusterissuer"{
  depends_on = [helm_release.cert-manager]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
YAML
}

resource "helm_release" "argocd" {
  
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.kubernetes_argocd_namespace
  version    = var.argocd_helm_chart_version == "" ? null : var.argocd_helm_chart_version

  create_namespace = true
  values = [
    templatefile(
      "${path.module}/templates/values.yaml.tpl",
      {
        "argocd_server_host"          = var.argocd_server_host            
        "argocd_ingress_enabled"                 = var.argocd_ingress_enabled
        "argocd_ingress_tls_acme_enabled"        = var.argocd_ingress_tls_acme_enabled
        "argocd_ingress_ssl_passthrough_enabled" = var.argocd_ingress_ssl_passthrough_enabled
        "argocd_ingress_class"                   = var.argocd_ingress_class
        "argocd_ingress_tls_secret_name"         = var.argocd_ingress_tls_secret_name
      }
    )
  ]
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }
}

module "check_namespace" {
  source = "./modules/check-namespace"
  name   = "keycloak"
}
module "check_namespace_mongo" {
  source = "./modules/check-namespace"
  name   = "mongo"
}
//keycloak deployment
data "kubectl_file_documents" "docs" {
    content = file("./manifests/keycloak.yaml")
}

resource "kubectl_manifest" "keycloak" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}
resource "kubernetes_namespace" "mongo" {
  metadata {
    name = "mongo"
  }
}
//mongo deployment
data "kubectl_file_documents" "mongo" {
    content = file("./manifests/mongodb.yaml")
}

resource "kubectl_manifest" "mongo" {
    for_each  = data.kubectl_file_documents.mongo.manifests
    yaml_body = each.value
}





