resource "google_storage_bucket" "main" {
  name                        = var.gcs_backend_bucket
  location                    = "us-west1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  soft_delete_policy {
    retention_duration_seconds = 2592000 # 30 days
  }
  lifecycle {
    prevent_destroy = true
  }
}
