# A Terraform module to create a S3 Bucket

This module can be used to provision a S3 Bucket.

## How to use this module

This module is intended to be used as a part of an infrastructure module composition.

Define the AWS provider in your main module, then add the following module block:

```terraform
module "s3_bucket" {
  # module's source
  source = "../modules/s3_bucket"

  # set the variables

  # choose between 'bucket_prefix' or 'bucket', if you provide both, 'bucket_prefix' will overwrite 'bucket'
  bucket        = "test_bucket"
  bucket_prefix = "test_bucket_prefix"
  force_destroy = true
  tags          = {
    "key1" = "value1",
    "key2" = "value2",
  }

  # versioning
  versioning_status = "Enabled"

  # cors rules
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT", "POST"]
      allowed_origins = ["https://s3-website-test.hashicorp.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    },
  ]

  # bucket policy
  bucket_policy = {
    version = "2012-10-17"
    id = "test_bucket_policy"
    statements = [
      {
        sid              = "read-access"
        effect           = "Allow"
        principal_arns   = "arn:aws:iam::123456789012:role/TestRole"
        actions          = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        resourceSuffixes = [
          "/folder1/*"
        ]
        conditions = [
          {
            operator = "StringEquals"
            variable = "aws:PrincipalTag/email"
            values   = [
              "test@mail.com"
            ]
          }
        ]
      }
    ]
  }

  # public access block
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = true

  # ACLs
  access_control_policy_grants = [
    {
      grantee_type = "CanonicalUser"
      grantee_id   = "79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be"
      permission   = "READ"
    }
  ]
  owner_id = "79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be"

  # object lock (retention configuration)
  days = 5
  mode = "COMPLIANCE"

  # lifecycle configuration
  # note: every rule deployed with this module will be automatically enabled
  lifecycle_rules = {
    "lifecycle-rule-01" = {
      rule_filter_prefix       = "test-prefix"
      object_size_greater_than = 5
      object_size_less_than    = 10

      noncurrent_version_transition = {
        noncurrent_days           = 80
        storage_class             = "GLACIER"
        newer_noncurrent_versions = 2
      }

      noncurrent_version_expiration = {
        noncurrent_days           = 180
        newer_noncurrent_versions = 3
      }

      transition = {
        days          = 30
        storage_class = "STANDARD_IA"
      }

      expiration = {
        days = 120
      }
    },
    "lifecycle-rule-02" = {
      rule_filter_prefix = "other-test-prefix"
      rule_status        = "Disabled"

      abort_incomplete_multipart_upload = {
        days_after_initiation = 60
      }
    }
  }

  # Access Logs
  access_logs_target_bucket = "mybucket"
  access_logs_target_prefix_template = "log/$${bucket_name}/"

  # Server Side Encryption
  sse_algorithm     = "aws:kms"
  kms_master_key_id = "aws/s3"
}
```

## Secure Transport Enforcement

The module automatically attaches a bucket policy that blocks all unsecured 
(HTTP) access to the S3 bucket. The policy uses the AWS aws:SecureTransport 
condition to ensure that only HTTPS-encrypted requests are allowed.
