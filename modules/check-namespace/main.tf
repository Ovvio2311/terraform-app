data "google_client_config" "default" {}

data "google_container_cluster" "primary" {
  name     = "${var.cluster_name}"
  location = "us-central1-c"
}
provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}
variable "name" {
  type        = string
  default     = "default"
}
variable "cluster_name" {
  type        = string
  default     = "default"
}

resource "null_resource" "check-namespace" {

  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<SCRIPT
      var=$(kubectl get namespaces|grep ${var.name}| wc -l)
      if [ "$var" -eq "0" ]
      then kubectl create namespace ${var.name}
      # else echo '${var.name} already exists' >&3
      fi
    SCRIPT
  }
}

output "namespace_name" {
  value = var.name
}

output "id" {
  value = null_resource.check-namespace.id
}
