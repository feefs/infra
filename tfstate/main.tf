resource "google_storage_bucket" "tfstate" {
  name                        = var.gcs_backend_bucket
  location                    = "us-west1"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}
