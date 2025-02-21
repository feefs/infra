module "gce-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "3.2"

  cos_image_name = "cos-stable-117-18613-164-28"
  container = {
    name  = "soft-serve"
    image = "ghcr.io/charmbracelet/soft-serve:v0.8.2"
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

data "google_compute_subnetwork" "default" {
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
  network_interface {
    subnetwork = data.google_compute_subnetwork.default.self_link
    access_config {}
  }
  metadata = {
    gce-container-declaration = module.gce-container.metadata_value
  }
  labels = {
    container-vm = module.gce-container.vm_container_label
  }
}
