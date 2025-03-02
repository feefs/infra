resource "google_artifact_registry_repository" "main" {
  location      = "us-west1"
  repository_id = "soft-serve-gcloud"
  format        = "docker"
}

data "google_artifact_registry_docker_image" "main" {
  location      = google_artifact_registry_repository.main.location
  repository_id = google_artifact_registry_repository.main.repository_id
  image_name    = "${google_artifact_registry_repository.main.name}:latest"
}

module "gce-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "3.2"

  cos_image_name = "cos-stable-117-18613-164-28"
  container = {
    name  = "soft-serve"
    image = data.google_artifact_registry_docker_image.main.self_link
    env = [
      {
        name  = "SOFT_SERVE_INITIAL_ADMIN_KEYS",
        value = var.admin_ssh_key,
      }
    ]
    volumeMounts = [
      {
        mountPath = "/soft-serve"
        readOnly  = false
      }
    ]
    stdin = true
    tty   = true
  }
  volumes = [
    {
      hostPath = {
        path = "/home/soft-serve"
      }
    }
  ]
  restart_policy = "Always"
}

resource "google_service_account" "main" {
  account_id   = "soft-serve"
  display_name = "Soft Serve service account"
}

data "google_project" "main" {}

resource "google_project_iam_member" "main" {
  project = data.google_project.main.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.main.email}"
}

data "google_compute_subnetwork" "main" {
  name   = "default"
  region = "us-west1"
}

resource "google_compute_instance" "main" {
  name         = "soft-serve"
  zone         = "us-west1-a"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }
  service_account {
    email  = google_service_account.main.email
    scopes = ["cloud-platform"]
  }
  network_interface {
    subnetwork = data.google_compute_subnetwork.main.self_link
    access_config {
      nat_ip = google_compute_address.main.address
    }
  }
  metadata = {
    gce-container-declaration = module.gce-container.metadata_value
  }
  labels = {
    container-vm = module.gce-container.vm_container_label
  }
}

resource "google_compute_address" "main" {
  name         = "soft-serve-ip"
  region       = "us-west1"
  address_type = "EXTERNAL"
}
