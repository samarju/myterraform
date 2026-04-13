<!-- BEGIN_TF_DOCS -->
<!-- THE CONTENT OF THIS FILE IS GENERATED -->
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
  access_logs_target_prefix_template = "logs/$${bucket_name}/"

  # Server Side Encryption
  sse_algorithm     = "aws:kms"
  kms_master_key_id = "aws/s3"
}
```

## Secure Transport Enforcement

The module automatically attaches a bucket policy that blocks all unsecured
(HTTP) access to the S3 bucket. The policy uses the AWS aws:SecureTransport
condition to ensure that only HTTPS-encrypted requests are allowed.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| aws\_version | ../../global/versions | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.s3_bucket_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_cors_configuration.s3_bucket_cors_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.s3_bucket_lifecycle_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_object_lock_configuration.s3_bucket_object_lock_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_policy.external_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.s3_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| access\_control\_policy\_grants | Configuration block that sets the ACL permissions for an object per grantee. | `[]` | no |
| access\_logs\_target\_bucket | [Optional] Name of the bucket where you want Amazon S3 to store server access logs. | `null` | no |
| access\_logs\_target\_prefix | [Optional] Prefix for all log object keys. | `null` | no |
| block\_public\_acls | [Optional] Whether Amazon S3 should block public ACLs for this bucket. Defaults to true. Enabling this setting does not affect existing policies or ACLs. When set to true causes the following behavior: - PUT Bucket acl and PUT Object acl calls will fail if the specified ACL   allows public access - PUT Object calls will fail if the request includes an object ACL | `true` | no |
| block\_public\_policy | [Optional] Whether Amazon S3 should block public bucket policies for this bucket. Defaults to true. Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to: - Reject calls to PUT Bucket policy if the specified bucket policy   allows public access | `true` | no |
| bucket | [Optional, Forces new resource] The name of the bucket. If omitted, Terraform will assign a random, unique name. Must be lowercase and less than or equal to 63 characters in length. If both bucket and bucket\_prefix are provided, bucket\_prefix has precedence and will overwrite bucket. | `null` | no |
| bucket\_acl | [Optional] Conflicts with access\_control\_policy. The canned ACL to apply to the bucket. | `null` | no |
| bucket\_policy | [Optional] A access policy that allows you to define permissions for the resources within an S3 bucket. This policy specifies who (which users or accounts) can access the bucket or the objects within it and what actions (such as reading, writing, or deleting files) they can perform. | `null` | no |
| bucket\_prefix | [Optional, Forces new resource] Creates a unique bucket name beginning with the specified prefix. Conflicts with bucket. Must be lowercase and less than or equal to 37 characters in length. If both bucket and bucket\_prefix are provided, bucket\_prefix has precedence and will overwrite bucket. | `null` | no |
| cors\_rules | Define the CORS (Cross-Origin Resource Sharing) rules for storage account. | `[]` | no |
| force\_destroy | [Optional] A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `true` | no |
| ignore\_public\_acls | [Optional] Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to true. Enabling this setting does not affect the persistence of any existing ACLs and doesn't prevent new public ACLs from being set. When set to true causes Amazon S3 to: - Ignore public ACLs on this bucket and any objects that it contains | `true` | no |
| kms\_master\_key\_id | [Optional] AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse\_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse\_algorithm is aws:kms. | `null` | no |
| lifecycle\_rules | [Required] List of configuration blocks describing the rules managing the replication. It is not feasible to combine either "object\_size\_greater\_than" and/or "object\_size\_less\_than" abort\_incomplete\_multipart\_upload together in one rule! | `{}` | no |
| owner\_id | [Optional] The ID of the owner. | `null` | no |
| restrict\_public\_buckets | [Optional] Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to true. Enabling this setting does not affect the previously stored bucket policy, except that public and cross-account access within the public bucket policy, including non-public delegation to specific accounts, is blocked. When set to true: - Only the bucket owner and AWS Services can access this buckets   if it has a public policy | `true` | no |
| retention\_days | [Optional] The number of days that you want to specify for the default retention period. | `null` | no |
| retention\_mode | [Optional] The default Object Lock retention mode you want to apply to new objects placed in the specified bucket. Valid values: COMPLIANCE, GOVERNANCE. | `null` | no |
| sse\_algorithm | [Optional] Server-side encryption algorithm to use. Valid values are AES256 and aws:kms" | `"aws:kms"` | no |
| tags | A list of tags to apply to the resource. | `{}` | no |
| transition\_default\_minimum\_object\_size | [Optional] The default minimum object size behavior applied to the lifecycle configuration. Valid values: all\_storage\_classes\_128K (default), varies\_by\_storage\_class. To customize the minimum object size for any transition you can add a filter that specifies a custom object\_size\_greater\_than or object\_size\_less\_than value. Custom filters always take precedence over the default transition behavior. | `"all_storage_classes_128K"` | no |
| versioning\_status | [Required] The versioning state of the bucket. Valid values: Enabled, Suspended, or Disabled. Disabled should only be used when creating or importing resources that correspond to unversioned S3 buckets. | `"Enabled"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_arn | The ARN of the bucket. Will be of format arn:aws:s3:::bucketname. |
| bucket\_domain\_name | The bucket domain name. Will be of format bucketname.s3.amazonaws.com. |
| bucket\_id | The name of the bucket. |
| bucket\_regional\_domain\_name | The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL. |
| hosted\_zone\_id | The Route 53 Hosted Zone ID for this bucket's region. |
| kms\_master\_key\_id | KMS CMK ID used by the S3 bucket (if any) |
| region | The AWS region this bucket resides in. |
| s3\_bucket\_policy | The s3\_bucket\_policy document, which is attached to the S3 bucket. |
| tags\_all | A map of tags assigned to the resource, including those inherited from the aws provider's default\_tags configuration block. |
<!-- END_TF_DOCS -->
