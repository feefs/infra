terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.20.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

module "tfstate" {
  source             = "./tfstate"
  gcs_backend_bucket = "${var.project_id}-tf-state"
}
