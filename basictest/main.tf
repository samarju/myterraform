provider "aws" {
  region = "eu-central-1"
}

# Get identity data
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "gov" {
  bucket = format("instance-aws-servicelog-bucket-%s-%s-an", 
    data.aws_caller_identity.current.account_id, 
    data.aws_region.current.id
  )
  bucket_namespace = "account-regional"
  object_lock_enabled = true
  force_destroy = true 
}

resource "aws_s3_bucket_versioning" "gov" {
  bucket = aws_s3_bucket.gov.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "gov" {
  bucket = aws_s3_bucket.gov.id

  # object_lock_enabled = "Enabled"

  # rule {
  #   default_retention {
  #     mode  = "GOVERNANCE"  # ← Governance mode
  #     days  = 0            # days in retention
  #   }
  # }
}