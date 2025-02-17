locals {
  gcs_backend_bucket = "${var.project_id}-tf-state"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.20.0"
    }
  }
  backend "gcs" {
    bucket = local.gcs_backend_bucket
  }
}

provider "google" {
  project = var.project_id
}

module "tf-state" {
  source             = "./tf-state"
  gcs_backend_bucket = local.gcs_backend_bucket
}

module "soft-serve" {
  source        = "./soft-serve"
  project_id    = var.project_id
  admin_ssh_key = var.admin_ssh_key
}
