variable "bucket" {
  type        = string
  description = <<-EOT
    [Optional, Forces new resource]
    The name of the bucket.
    If omitted, Terraform will assign a random, unique name.
    Must be lowercase and less than or equal to 63 characters in length.
    If both bucket and bucket_prefix are provided,
    bucket_prefix has precedence and will overwrite bucket.
  EOT
  default     = null
}

variable "bucket_prefix" {
  type        = string
  description = <<-EOT
    [Optional, Forces new resource]
    Creates a unique bucket name beginning with the specified prefix.
    Conflicts with bucket.
    Must be lowercase and less than or equal to 37 characters in length.
    If both bucket and bucket_prefix are provided,
    bucket_prefix has precedence and will overwrite bucket.
  EOT
  default     = null
}

variable "force_destroy" {
  type        = bool
  description = <<-EOT
    [Optional]
    A boolean that indicates all objects (including any locked objects)
    should be deleted from the bucket so that the bucket can be destroyed
    without error.
    These objects are not recoverable.
  EOT
  default     = true
}

variable "tags" {
  type        = map(string)
  description = <<-EOT
    A list of tags to apply to the resource.
  EOT
  default     = {}
}

# Versioning
variable "versioning_status" {
  type        = string
  description = <<-EOT
    [Required]
    The versioning state of the bucket.
    Valid values: Enabled, Suspended, or Disabled.
    Disabled should only be used when creating or importing resources that
    correspond to unversioned S3 buckets.
  EOT
  default     = "Enabled"
}

# CORS Rules
variable "cors_rules" {
  description = <<-EOT
    Define the CORS (Cross-Origin Resource Sharing) rules for storage account.
  EOT
  type = list(object({
    allowed_origins = list(string)
    allowed_methods = list(string)
    allowed_headers = optional(list(string), null)
    expose_headers  = optional(list(string), null)
    max_age_seconds = number
  }))
  default = []
}

variable "bucket_policy" {
  description = <<-EOT
    [Optional]
    A access policy that allows you to define permissions for the resources
    within an S3 bucket. This policy specifies who (which users or accounts) can
    access the bucket or the objects within it and what actions
    (such as reading, writing, or deleting files) they can perform.
  EOT
  default     = null
  # Hinweis:
  # Obwohl dieses Feld in der Typdefinition als optional markiert ist,
  # ist es erforderlich. Aufgrund der Validierungsreihenfolge in Terraform
  # (Typüberprüfung vor benutzerdefinierten Validierungen) müssen wir es
  # hier als optional deklarieren, um benutzerdefinierte Validierungslogik
  # zu ermöglichen, die seine Präsenz sicherstellt.
  type = object({
    version = optional(string, "2012-10-17")
    id      = optional(string, null)
    statements = list(object({
      sid            = optional(string, "")
      effect         = optional(string, "Allow")
      principal_arns = list(string)
      actions        = list(string)
      # If only access on bucket level is required, you need to set [""] as resourceSuffixes
      resourceSuffixes = optional(list(string), ["/*", ""])
      conditions = optional(list(object({
        operator = string
        variable = string
        values   = list(string)
      })), [])
    }))
  })

  validation {
    error_message = <<-EOT
      The Id field must use only alphanumeric characters, hyphens,
      or underscores if provided. Must be guid and can be followed by custom
      name.

      e.g.: <guid>-<custom_name>

      Note: The hyphen between guid and custom name is mandatory.

    EOT
    condition = (
      var.bucket_policy == null
      ||
      (var.bucket_policy != null && try(var.bucket_policy.id, null) == null)
      ||
      (can(
        regex(join("", [
          "^",
          "([a-fA-F0-9]{8})",
          "-",
          "([a-fA-F0-9]{4})",
          "-",
          "([1-5][a-fA-F0-9]{3})",
          "-",
          "([89abAB][a-fA-F0-9]{3})",
          "-",
          "([a-fA-F0-9]{12})",
          "(-.+)?",
          "$"
          ]),
          var.bucket_policy.id
        )
        )
    ))
  }

  validation {
    error_message = <<-EOT
      There must be at least one Statement in the bucket policy.
      Each policy requires at least one statement to define access rules.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      length(try(var.bucket_policy.statements, [])) > 0
    )
  }

  validation {
    error_message = <<-EOT
      Sid, if set, must use only alphanumeric characters, hyphens,
      or underscores to ensure consistency.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        (
          statement.sid == ""
          ||
          can(regex("^[a-zA-Z0-9_-]+$", statement.sid))
        )
      ])
    )
  }

  validation {
    error_message = <<-EOT
      Effect must be either 'Allow' or 'Deny'.
      This defines whether the statement allows or denies access.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      can(alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        contains(["Allow", "Deny"], statement.effect)
      ]))
    )
  }

  validation {
    error_message = <<-EOT
      Each Statement must have at least one Principal_Arn.
      This specifies the users or accounts the policy applies to.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      can(alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        (
          length(statement.principal_arns) > 0
        )
      ]))
    )
  }

  validation {
    error_message = <<-EOT
      All Principal_Arns must be valid ARNs.
      Ensure each ARN follows the correct format.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      can(alltrue([
        for arn in flatten([
          for statement in try(var.bucket_policy.statements, []) :
          statement.principal_arns
        ]) :
        (
          length(regexall("^arn:[^:]+:[^:]*:[^:]*:[^:]*:[^:]+$", arn)) > 0
        )
        ])
    ))
  }

  validation {
    error_message = <<-EOT
      Each Statement must have at least one Action.
      Actions define what operations are permitted or denied.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      can(alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        (
          length(statement.actions) > 0
        )
        ])
    ))
  }

  validation {
    error_message = <<-EOT
      All Actions must start with 's3:'.
      This ensures actions are valid S3 operations.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      can(alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        alltrue([
          for action in statement.actions :
          startswith(action, "s3:")
        ])
        ])
    ))
  }

  validation {
    error_message = <<-EOT
      All conditions must use valid operators, variables and values.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        alltrue([
          for condition in statement.conditions :
          (
            contains(
              concat(
                ["Null"],
                flatten([
                  for prefix in ["", "ForAnyValue:", "ForAllValues:"] : [
                    for base in [
                      "StringEquals", "StringNotEquals", "StringEqualsIgnoreCase",
                      "StringNotEqualsIgnoreCase", "StringLike", "StringNotLike",
                      "NumericEquals", "NumericNotEquals", "NumericLessThan",
                      "NumericLessThanEquals", "NumericGreaterThan",
                      "NumericGreaterThanEquals", "DateEquals", "DateNotEquals",
                      "DateLessThan", "DateLessThanEquals", "DateGreaterThan",
                      "DateGreaterThanEquals", "Bool", "BinaryEquals",
                      "IpAddress", "NotIpAddress", "ArnLike", "ArnEquals",
                      "ArnNotEquals", "ArnNotLike"
                      ] : [
                      for postfix in ["", "IfExists"] : "${prefix}${base}${postfix}"
                  ]]
                ])
              ),
              condition.operator
            )
            && condition.variable != null
            && length(condition.values) > 0
          )
        ])
      ])
    )
  }

  validation {
    error_message = <<-EOT
      At least one resource suffix must be added to list,
      if resourceSuffixes attribute is specified on a bucket policy statement.
    EOT
    condition = (
      var.bucket_policy == null
      ||
      alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        (
          length(statement.resourceSuffixes) > 0
        )
      ])
    )
  }

  validation {
    error_message = <<-EOT
      Resource suffixes must be in the correct format.
      It must match the allowed S3 keys and can include AWS policy placeholders with $ {...}. (no space between $ and {)
      The suffix can be empty or must start with a /.
      Examples:
        - ""
        - "/*"
        - "/$ {aws:PrincipalTag/xyz}/*" (no space between $ and {)
    EOT
    condition = (
      var.bucket_policy == null
      ||
      alltrue([
        for statement in try(var.bucket_policy.statements, []) :
        alltrue([
          for resourceSuffix in statement.resourceSuffixes :
          (
            // Allowed s3 object characters: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html#object-key-guidelines
            // Allowed tag characters: https://docs.aws.amazon.com/mediaconnect/latest/ug/tagging-restrictions.html
            can(regex("^(\\/(\\*|(?:([a-zA-Z0-9!\\-_.*'()]+|\\$\\{[a-zA-Z0-9\\/.:+=@_-]+\\})+\\/)*(?:([a-zA-Z0-9!\\-_.*'()]+|\\$\\{[a-zA-Z0-9\\/.:+=@_-]+\\})\\/?)))$|^\\/?$", resourceSuffix))
          )
        ])
      ])
    )
  }
}

variable "block_public_acls" {
  type        = bool
  description = <<-EOT
    [Optional]
    Whether Amazon S3 should block public ACLs for this bucket.
    Defaults to true.
    Enabling this setting does not affect existing policies or ACLs.
    When set to true causes the following behavior:
    - PUT Bucket acl and PUT Object acl calls will fail if the specified ACL
      allows public access
    - PUT Object calls will fail if the request includes an object ACL
  EOT
  default     = true
}

variable "block_public_policy" {
  type        = bool
  description = <<-EOT
    [Optional]
    Whether Amazon S3 should block public bucket policies for this bucket.
    Defaults to true.
    Enabling this setting does not affect the existing bucket policy.
    When set to true causes Amazon S3 to:
    - Reject calls to PUT Bucket policy if the specified bucket policy
      allows public access
  EOT
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = <<-EOT
    [Optional]
    Whether Amazon S3 should ignore public ACLs for this bucket.
    Defaults to true.
    Enabling this setting does not affect the persistence of any existing ACLs
    and doesn't prevent new public ACLs from being set.
    When set to true causes Amazon S3 to:
    - Ignore public ACLs on this bucket and any objects that it contains
  EOT
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  description = <<-EOT
    [Optional]
    Whether Amazon S3 should restrict public bucket policies for this bucket.
    Defaults to true.
    Enabling this setting does not affect the previously stored bucket policy,
    except that public and cross-account access within the public bucket policy,
    including non-public delegation to specific accounts, is blocked.
    When set to true:
    - Only the bucket owner and AWS Services can access this buckets
      if it has a public policy
  EOT
  default     = true
}

# Bucket ACLs
variable "bucket_acl" {
  type        = string
  description = <<-EOT
    [Optional]
    Conflicts with access_control_policy.
    The canned ACL to apply to the bucket.
  EOT
  default     = null
}

variable "access_control_policy_grants" {
  description = <<-EOT
    Configuration block that sets the ACL permissions for an object
    per grantee.
  EOT
  type = list(object({
    grantee_email_address = optional(string)
    grantee_id            = optional(string)
    grantee_type          = optional(string)
    grantee_uri           = optional(string)
    permission            = string
  }))
  default = []
}

variable "owner_id" {
  type        = string
  description = <<-EOT
    [Optional] The ID of the owner.
  EOT
  default     = null
}

# Object Lock Configuration
variable "retention_days" {
  type        = number
  description = <<-EOT
    [Optional]
    The number of days that you want to specify for the default
    retention period.
  EOT
  validation {
    condition     = var.retention_days == null || var.retention_days > 0
    error_message = "retention_days must be greater than 0 if set."
  }
  default     = null
}

variable "retention_mode" {
  type        = string
  description = <<-EOT
    [Optional]
    The default Object Lock retention mode you want to apply to
    new objects placed in the specified bucket.
    Valid values: COMPLIANCE, GOVERNANCE.
  EOT
  validation {
    condition     = var.retention_mode == null || contains(["COMPLIANCE", "GOVERNANCE"], var.retention_mode)
    error_message = "retention_mode must be either 'COMPLIANCE' or 'GOVERNANCE'."
  }
  default     = "GOVERNANCE"
}

# Lifecycle Rules
variable "lifecycle_rules" {
  description = <<-EOT
    [Required]
    List of configuration blocks describing the rules managing the replication.
    It is not feasible to combine either "object_size_greater_than" and/or "object_size_less_than"
    abort_incomplete_multipart_upload together in one rule!
  EOT
  type = map(object({
    rule_filter_prefix       = optional(string)
    object_size_greater_than = optional(number, null)
    object_size_less_than    = optional(number, null)
    rule_status              = optional(string, "Enabled")

    noncurrent_version_transition = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = number
      storage_class             = string
    }), null)

    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = number
    }), null)

    transition = optional(object({
      days          = number
      storage_class = string
    }), null)

    expiration = optional(object({
      days = optional(number)
      expired_object_delete_marker = optional(bool)
    }), null)

    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }), null)
  }))

  validation {
    condition = alltrue([
      for key, rule in var.lifecycle_rules :
      (
        rule.object_size_greater_than == null && rule.object_size_less_than == null ||
        rule.abort_incomplete_multipart_upload == null
      )
    ])
    error_message = "Cannot set object size filters together with abort_incomplete_multipart_upload. Choose one option between."
  }

  validation {
    condition = alltrue([
      for key, rule in var.lifecycle_rules :
      (
        rule.noncurrent_version_transition != null ||
        rule.noncurrent_version_expiration != null ||
        rule.transition != null ||
        rule.expiration != null ||
        rule.abort_incomplete_multipart_upload != null
      )
    ])
    error_message = "At least one action needs to be specified in a rule."
  }
  validation {
    condition = alltrue([
      for key, rule in var.lifecycle_rules :
      rule.noncurrent_version_expiration == null || rule.noncurrent_version_expiration.noncurrent_days > 0
    ])
    error_message = "noncurrent_days must be greater than 0."
  }
  default = {}
}

# Server Access Logs
variable "access_logs_target_bucket" {
  type        = string
  description = <<-EOT
    [Optional]
    Name of the bucket where you want Amazon S3 to store server access logs.
  EOT
  default     = null
}

variable "access_logs_target_prefix_template" {
  type        = string
  description = <<-EOT
    [Optional]
    Template string to generate the prefix for all log object keys.
  EOT
  default     = null
}

# Encryption
variable "sse_algorithm" {
  type        = string
  description = <<-EOT
    [Optional]
    Server-side encryption algorithm to use.
    Valid values are AES256 and aws:kms"
  EOT
  validation {
    condition = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = format(
      <<-EOT
        The value: '%s' is not supported.
        Possible values are: 'AES256' and 'aws:kms'
      EOT
      ,
      var.sse_algorithm
    )
  }
  default = "aws:kms"
}

variable "kms_master_key_id" {
  type        = string
  description = <<-EOT
    [Optional]
    AWS KMS master key ID used for the SSE-KMS encryption.
    This can only be used when you set the value of sse_algorithm as aws:kms.
    The default aws/s3 AWS KMS master key is used if this element is absent
    while the sse_algorithm is aws:kms.
  EOT
  default     = null
}

variable "transition_default_minimum_object_size" {
  type        = string
  description = <<-EOT
    [Optional]
    The default minimum object size behavior applied to the lifecycle configuration.
    Valid values: all_storage_classes_128K (default), varies_by_storage_class.
    To customize the minimum object size for any transition you can add a filter that
    specifies a custom object_size_greater_than or object_size_less_than value.
    Custom filters always take precedence over the default transition behavior.
  EOT
  default     = "all_storage_classes_128K"
}

variable "bucket_namespace" {
  type        = string
  description = "Account-level namespace for the bucket (regional namespace feature). Valid values: account-regional, global."
  default     = "global"
  validation {
    condition     = contains(["account-regional", "global"], var.bucket_namespace)
    error_message = "bucket_namespace must be either 'account-regional' or 'global'."
  }
}

variable "replication_destination_bucket_arn" {
  type        = string
  description = "ARN of the destination bucket for replication. If set, replication config and IAM role are created automatically."
  default     = null
}

variable "replication_destination_account_id" {
  type        = string
  description = "Destination AWS account ID for cross-account replication. Required when using access_control_translation."
  default     = null
}