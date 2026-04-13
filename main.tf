provider "aws" {
  region = "eu-central-1"
  profile = "testing"
}

module "s3_bucket" {
  source = "./modules/s3_bucket"
  bucket = "my-simple-bucket"
  retention_mode = "GOVERNANCE"
  retention_days = 1  # or however many days you want
  bucket_namespace = "account-regional"
  # replication_destination_bucket_arn = "arn:aws:s3:::simple-bucket-114563865850-eu-central-1-an"
  # replication_destination_account_id = "114563865850"
  replication_rules = [
    {
      id            = "replicate-to-account-375553085088"
      priority      = 1
      # prefix        = "team-b/"
      dest_bucket   = "arn:aws:s3:::simple-bucket-375553085088-eu-central-1-an"
      dest_account  = "375553085088"
      storage_class = "STANDARD"
    },
    {
      id            = "replicate-to-account-114563865850"
      priority      = 2
      # prefix        = "team-c/"
      dest_bucket   = "arn:aws:s3:::simple-bucket-114563865850-eu-central-1-an"
      dest_account  = "114563865850"
      storage_class = "STANDARD"
    }
  ]
  # lifecycle_rules = {
  #   expire-all = {
  #     expiration = {
  #       days = 90
  #     }
  #     noncurrent_version_expiration = {
  #       noncurrent_days = 1
  #     }
  #   }
  #   clean-delete-markers = {
  #     expiration = {
  #       expired_object_delete_marker = true
  #     }
  #   }
  # }
  # bucket_policy = {
  #   statements = [
  #     {
  #       sid            = "AllowCrossAccountRead"
  #       effect         = "Allow"
  #       principal_arns = ["arn:aws:iam::329863774746:root"]
  #       actions        = ["s3:GetObject"]
  #       resourceSuffixes = ["/*"]
  #     }
  #   ]
  # }
}