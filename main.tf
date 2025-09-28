locals {
  gcs_backend_bucket = "${var.project_id}-tf-state"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.4.0"
    }
  }
  backend "gcs" {
    bucket = local.gcs_backend_bucket
  }
}

provider "google" {
  project = var.project_id
}

resource "google_project_service" "project" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "storage-component.googleapis.com",
    "logging.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

module "tf-state" {
  source             = "./tf-state"
  gcs_backend_bucket = local.gcs_backend_bucket
}

module "soft-serve" {
  source        = "./soft-serve"
  admin_ssh_key = var.soft_serve_admin_ssh_key
}
