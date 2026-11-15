locals {
  docker_image_name = "soft-serve-gcloud"
  cos_image_name    = "cos-133-19999-44-261"
  startup_script_config = templatefile("${path.module}/startup-script-config.tftpl", {
    disk_device_name              = "soft-serve-data"
    registry                      = "${google_artifact_registry_repository.main.location}-docker.pkg.dev"
    image                         = data.google_artifact_registry_docker_image.main.self_link
    soft_serve_initial_admin_keys = var.admin_ssh_key
    soft_serve_gcs_backup_bucket  = google_storage_bucket.main.name
  })
}

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
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  soft_delete_policy {
    retention_duration_seconds = 2592000 # 30 days
  }
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "main" {
  for_each = toset([
    "roles/storage.objectUser",
    "roles/storage.legacyBucketReader",
  ])
  bucket = google_storage_bucket.main.name
  role   = each.key
  member = "serviceAccount:${google_service_account.main.email}"
}

### COMPUTE INSTANCE###
module "startup-scripts" {
  source  = "terraform-google-modules/startup-scripts/google"
  version = "2.0"
}

data "google_compute_image" "main" {
  name    = local.cos_image_name
  project = "cos-cloud"
}

data "google_artifact_registry_docker_image" "main" {
  location      = google_artifact_registry_repository.main.location
  repository_id = google_artifact_registry_repository.main.repository_id
  image_name    = "${local.docker_image_name}:latest"
}

resource "google_compute_network" "main" {
  name                    = "soft-serve-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "soft-serve-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.main.id
}

resource "google_compute_address" "main" {
  name         = "soft-serve-ip"
  region       = "us-west1"
  address_type = "EXTERNAL"
}

resource "google_compute_firewall" "git_ssh" {
  name                    = "allow-soft-serve-git-ssh"
  network                 = google_compute_network.main.id
  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.main.email]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "host_ssh_iap" {
  name                    = "allow-soft-serve-host-ssh-iap"
  network                 = google_compute_network.main.id
  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.main.email]
  allow {
    protocol = "tcp"
    ports    = ["23231"]
  }
}

resource "google_compute_disk" "main" {
  name = "soft-serve-data"
  zone = "us-west1-a"
  type = "pd-standard"
  size = 10
  lifecycle {
    prevent_destroy = true
  }
}

resource "terraform_data" "vm_replacement_triggers" {
  input = {
    # upstream terraform-google-modules/startup-scripts/google stdlib
    startup_script_sha256 = sha256(module.startup-scripts.content)
    # startup-script-config.tftpl, embeds docker image digest
    config_sha256 = sha256(local.startup_script_config)
    # startup-script
    custom_script_sha256 = filesha256("${path.module}/startup-script")
  }
}

resource "google_compute_instance" "main" {
  name         = "soft-serve"
  zone         = "us-west1-a"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = data.google_compute_image.main.self_link
    }
  }
  attached_disk {
    source      = google_compute_disk.main.self_link
    device_name = "soft-serve-data"
  }
  service_account {
    email  = google_service_account.main.email
    scopes = ["cloud-platform"]
  }
  network_interface {
    subnetwork = google_compute_subnetwork.main.self_link
    access_config {
      nat_ip = google_compute_address.main.address
    }
  }
  shielded_instance_config {
    enable_secure_boot = true
  }
  metadata = {
    startup-script         = module.startup-scripts.content
    startup-script-config  = local.startup_script_config
    startup-script-custom  = file("${path.module}/startup-script")
    google-logging-enabled = true
    enable-oslogin         = "TRUE"
  }
  lifecycle {
    replace_triggered_by = [
      terraform_data.vm_replacement_triggers,
    ]
  }
}
