

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
      gcloud container clusters get-credentials fyp-vpc-cluster --zone us-central1-c --project able-scope-413414      
    SCRIPT
  }
  provisioner "local-exec" {
    command = <<SCRIPT      
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
