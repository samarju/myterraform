data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name = var.bucket_namespace == "account-regional" ? "${var.bucket}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an" : var.bucket
}

resource "aws_s3_bucket" "s3_bucket" {
  #checkov:skip=CKV2_AWS_62:We don't have any use case for bucket notifications
  bucket           = local.bucket_name
  bucket_prefix    = var.bucket_prefix
  # bucket_namespace = var.bucket_namespace
  force_destroy       = var.force_destroy
  object_lock_enabled = var.retention_days != null && var.retention_days > 0 ? true : false
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_cors_configuration" "s3_bucket_cors_configuration" {
  for_each = { for k, v in var.cors_rules : k => v }
  bucket   = aws_s3_bucket.s3_bucket.id

  cors_rule {
    allowed_origins = each.value.allowed_origins
    allowed_methods = each.value.allowed_methods
    allowed_headers = each.value.allowed_headers
    expose_headers  = each.value.expose_headers
    max_age_seconds = each.value.max_age_seconds
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  count = (
    (var.bucket_acl != null)
    ||
    (length(var.access_control_policy_grants) > 0) ? 1 : 0
  )
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = var.bucket_acl
  access_control_policy {

    dynamic "grant" {
      for_each = var.access_control_policy_grants
      content {
        grantee {
          email_address = grant.value.grantee_email_address
          id            = grant.value.grantee_id
          type          = grant.value.grantee_type
          uri           = grant.value.grantee_uri
        }
        permission = grant.value.permission
      }
    }
    owner {
      id = var.owner_id
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "s3_bucket_object_lock_configuration" {
  count  = var.retention_days != null ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    default_retention {
      days = var.retention_days
      mode = var.retention_mode
    }
  }
}

locals {
  filter_conditions = { for key, value in var.lifecycle_rules :
    key => compact([value.rule_filter_prefix, value.object_size_greater_than, value.object_size_less_than])
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_configuration" {
  #checkov:skip=CKV_AWS_300: S3 lifecycle configuration does not set a period for aborting failed uploads
  # abort_incomplete_multipart_upload can't be specified in a rule that has a filter that uses object tags or object sizes
  # s. https://docs.aws.amazon.com/AmazonS3/latest/userguide/intro-lifecycle-rules.html#intro-lifecycle-rules-actions  

  count                                  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket                                 = aws_s3_bucket.s3_bucket.id
  transition_default_minimum_object_size = var.transition_default_minimum_object_size

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = rule.value.rule_status

      # Combine filters into a single block when possible
      dynamic "filter" {
        for_each = length(local.filter_conditions[rule.key]) > 0 ? [1] : []
        content {
          dynamic "and" {
            for_each = length(local.filter_conditions[rule.key]) > 1 ? [1] : []
            content {
              prefix                   = rule.value.rule_filter_prefix
              object_size_greater_than = rule.value.object_size_greater_than
              object_size_less_than    = rule.value.object_size_less_than
            }
          }

          # Fallback for single filter conditions
          prefix                   = length(local.filter_conditions[rule.key]) > 1 ? null : rule.value.rule_filter_prefix
          object_size_greater_than = length(local.filter_conditions[rule.key]) > 1 ? null : rule.value.object_size_greater_than
          object_size_less_than    = length(local.filter_conditions[rule.key]) > 1 ? null : rule.value.object_size_less_than
        }
      }

      # Mutually exclusive sections
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? [1] : []
        content {
          newer_noncurrent_versions = rule.value.noncurrent_version_transition.newer_noncurrent_versions
          noncurrent_days           = rule.value.noncurrent_version_transition.noncurrent_days
          storage_class             = rule.value.noncurrent_version_transition.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [1] : []
        content {
          newer_noncurrent_versions = rule.value.noncurrent_version_expiration.newer_noncurrent_versions
          noncurrent_days           = rule.value.noncurrent_version_expiration.noncurrent_days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition != null ? [1] : []
        content {
          days          = rule.value.transition.days
          storage_class = rule.value.transition.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [1] : []
        content {
          days = rule.value.expiration.days
          expired_object_delete_marker = rule.value.expiration.expired_object_delete_marker
        }
      }

      # Only include abort_incomplete_multipart_upload if object size filters are not set
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload != null ? [1] : []
        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload.days_after_initiation
        }
      }
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.s3_bucket.id
  count = (
    var.access_logs_target_bucket != null
    &&
    var.access_logs_target_prefix_template != null
  ) ? 1 : 0

  target_bucket = var.access_logs_target_bucket

  # Render target prefix as a template string to allow for dynamic
  # values such as the bucket name
  target_prefix = templatestring(var.access_logs_target_prefix_template, {
    bucket_name = aws_s3_bucket.s3_bucket.id
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  # checkov:skip=CKV2_AWS_67: TODO: Take a look at the key rotation
  bucket = aws_s3_bucket.s3_bucket.id
  count  = var.sse_algorithm != null && var.kms_master_key_id != null ? 1 : 0

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_master_key_id
    }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  policy_id = try(var.bucket_policy.id, null)

  statement {
    sid    = "EnforceHTTPS"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = try(var.bucket_policy.statements, [])

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = formatlist("%s%s", aws_s3_bucket.s3_bucket.arn, statement.value.resourceSuffixes)
      principals {
        type        = "AWS"
        identifiers = statement.value.principal_arns
      }
      dynamic "condition" {
        for_each = (
          statement.value.conditions != null ? statement.value.conditions : []
        )
        content {
          test     = condition.value.operator
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_s3_bucket_policy" "external_access" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "random_id" "replication_role_suffix" {
  count       = length(var.replication_rules) > 0 ? 1 : 0
  byte_length = 3  # produces 5-6 hex chars
}

module "replication_iam_role" {
  count  = length(var.replication_rules) > 0 ? 1 : 0
  source = "../iam_role"

  name = "s3-replication-role-${random_id.replication_role_suffix[0].hex}"

  identities = [
    {
      principals = [{ type = "Service", identifiers = ["s3.amazonaws.com"] }]
    }
  ]

  inline_policy = {
    name = "s3-replication-policy"
    json = jsonencode({
      Version = "2012-10-17"
      Statement = concat(
        [
          {
            Effect   = "Allow"
            Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
            Resource = aws_s3_bucket.s3_bucket.arn
          },
          {
            Effect   = "Allow"
            Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
            Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
          }
        ],
        [
          for rule in var.replication_rules : {
            Effect   = "Allow"
            Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
            Resource = "${rule.dest_bucket}/*"
          }
        ]
      )
    })
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count = length(var.replication_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id
  role   = module.replication_iam_role[0].arn
  depends_on = [aws_s3_bucket_versioning.s3_bucket_versioning]
  dynamic "rule" {
    for_each = var.replication_rules
    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority
      filter {
        prefix = rule.value.prefix
      }
      destination {
        bucket        = rule.value.dest_bucket
        storage_class = rule.value.storage_class
        account       = rule.value.dest_account
        access_control_translation {
          owner = "Destination"
        }
      }
      delete_marker_replication {
        status = rule.value.delete_markers
      }
    }
  }
}