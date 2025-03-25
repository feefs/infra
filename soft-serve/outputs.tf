output "image_name" {
  value = join("", [
    google_artifact_registry_repository.main.location,
    "-docker.pkg.dev/",
    google_artifact_registry_repository.main.project,
    "/",
    google_artifact_registry_repository.main.repository_id,
    "/",
    google_artifact_registry_repository.main.name
  ])
}

output "static_ip_address" {
  value = google_compute_address.main.address
}
