

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
      gcloud container clusters get-credentials var.cluster_name --zone us-central1-c --project able-scope-413414
      var=$(kubectl get namespaces|grep ${var.name}| wc -l)
      if [ "$var" -eq "0" ]
      then kubectl create namespace ${var.name}
      else echo '${var.name} already exists' >&3
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
