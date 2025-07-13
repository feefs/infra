data "google_project" "main" {}

### IAM ###
resource "google_service_account" "main" {
  account_id   = "soft-serve"
  display_name = "Soft Serve service account"
}

resource "google_project_iam_member" "main" {
  project = data.google_project.main.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.main.email}"
}

### DOCKER ###
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

resource "google_artifact_registry_repository_iam_member" "main" {
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.main.email}"
}

### BACKUP BUCKET ###
resource "google_storage_bucket" "main" {
  name                        = "${data.google_project.main.project_id}-soft-serve-backup"
  location                    = "us-west1"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "main" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.main.email}"
}

### COMPUTE INSTANCE ###
module "gce-container" {
  source         = "terraform-google-modules/container-vm/google"
  version        = "3.2"
  cos_image_name = "cos-stable-121-18867-90-77"
  container = {
    name  = "soft-serve"
    image = data.google_artifact_registry_docker_image.main.self_link
    env = [
      {
        name  = "SOFT_SERVE_INITIAL_ADMIN_KEYS",
        value = var.admin_ssh_key,
      },
      {
        name  = "SOFT_SERVE_GCS_BACKUP_BUCKET",
        value = google_storage_bucket.main.name,
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

module "startup-scripts" {
  source  = "terraform-google-modules/startup-scripts/google"
  version = "2.0"
}

data "google_compute_subnetwork" "main" {
  name   = "default"
  region = "us-west1"
}

resource "google_compute_firewall" "main" {
  name          = "allow-soft-serve-ssh"
  network       = data.google_compute_subnetwork.main.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["23231"]
  }
}

resource "google_compute_address" "main" {
  name         = "soft-serve-ip"
  region       = "us-west1"
  address_type = "EXTERNAL"
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
    startup-script            = module.startup-scripts.content
    startup-script-custom     = file("${path.module}/startup-script")
    gce-container-declaration = module.gce-container.metadata_value
    google-logging-enabled    = true
  }
  labels = {
    container-vm = module.gce-container.vm_container_label
  }
}
