
output "client_token" {
  description = "The bearer token for auth"
  sensitive   = true
  value       = base64encode(data.google_client_config.default.access_token)
}

output "project" {
  value = data.google_client_config.default
  sensitive = true
}
output "datacluster" {
  value       = data.google_container_cluster.primary
}
/*output "gke_auth" {
  value = module.gke_auth
  sensitive = true
}

output "content" {
  value = kubernetes_manifest.cluster_issuer.manifest
}
*/
