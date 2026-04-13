variable "identities" {
  type = list(object({
    sid = optional(string)
    principals = list(object({
      type        = string
      identifiers = list(string)
    }))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  description = "List of entities who are entitled to use this role via 'sts:AssumeRole'."
  default     = []
}

variable "web_identities" {
  type = list(object({
    sid = optional(string)
    principals = list(object({
      type        = string
      identifiers = list(string)
    }))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  description = "List of entities who are entitled to use this role via 'sts:AssumeRoleWithWebIdentity'."
  default     = []
}

variable "saml_identities" {
  type = list(object({
    sid = optional(string)
    principals = list(object({
      type        = string
      identifiers = list(string)
    }))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  description = "List of entities who are entitled to use this role via 'sts:AssumeRoleWithSAML'."
  default     = []
}

variable "name_prefix" {
  type        = string
  description = <<DOC
    (Optional, Forces new resource) Creates a unique friendly name beginning with the specified prefix.
    If both name and name_prefix are provided, name_prefix has the higher priority and will overwrite name.
  DOC
  default     = null
}

variable "name" {
  type        = string
  description = <<DOC
    (Optional, Forces new resource) Friendly name of the role. If omitted, Terraform will assign a random, unique name.
    See IAM Identifiers for more information.
    If both name and name_prefix are provided, name_prefix has the higher priority and will overwrite name.
  DOC
  default     = null
}

variable "description" {
  type        = string
  description = "(Optional) Description of the role."
  default     = null
}

variable "force_detach_policies" {
  type        = bool
  description = "(Optional) Whether to force detaching any policies the role has before destroying it. Defaults to false."
  default     = false
}

variable "inline_policy" {
  type = object({
    name = string
    json = string
  })
  description = <<DOC
    (Optional) Inline policy to assign to the role. Policy document should be provided in the 'json' attribute
    as a JSON-formatted string. For more information about building IAM policy documents with Terraform,
    see the AWS IAM Policy Document Guide.
  DOC
  validation {
    condition     = var.inline_policy == null || try(length(var.inline_policy.name), 0) > 0
    error_message = "Policy name ('var.inline_policy.name') must not be empty."
  }
  validation {
    condition     = var.inline_policy == null || try(length(var.inline_policy.json), 0) > 0
    error_message = "Policy document ('var.inline_policy.json') must not be empty."
  }
  default = null
}

variable "exclusive_mgmt_of_inline_policy" {
  type        = bool
  description = <<DOC
    (Optional) Whether Terraform should exclusively manage inline policy associations.
    This includes removal of inline policies which are not explicitly configured here.
  DOC
  default     = true
}

variable "managed_policy_arns" {
  type = list(object({
    name = string
    arn  = string
  }))
  description = <<DOC
    (Optional) Set of IAM managed policy ARNs to attach to the IAM role.
    When configured and exclusive_mgmt_of_managed_policy_arns = true, Terraform will align the role's managed policy
    attachments with this set by attaching or detaching managed policies. If exclusive_mgmt_of_managed_policy_arns = false, 
    then Terraform will add the configured managed_policy_arns without removing any existing policy attachments,
    that are not managed by Terraform.
    If this attribute is not configured and exclusive_mgmt_of_managed_policy_arns is set to false, Terraform will
    ignore policy attachments to this resource. However, if exclusive_mgmt_of_managed_policy_arns is set to true, 
    Terraform will remove all managed policy attachments.
  DOC
  validation {
    condition     = alltrue([for v in coalesce(var.managed_policy_arns, []) : try(length(v.name), 0) > 0])
    error_message = "All managed policy names ('var.managed_policy_arns[*].name') must not be empty."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.managed_policy_arns, []) : try(length(v.arn), 0) > 0])
    error_message = "All managed policy ARNs ('var.managed_policy_arns[*].arn') must not be empty."
  }
  default = null
}

variable "exclusive_mgmt_of_managed_policy_arns" {
  type        = bool
  description = <<DOC
    (Optional) Whether Terraform should exclusively manage all managed policy attachments.
    This includes removal of managed IAM policies which are not explicitly configured here.
  DOC
  default     = true
}

variable "max_session_duration" {
  type        = number
  description = <<DOC
    (Optional) Maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting,
    the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours.
  DOC
  default     = 3600
}

variable "path" {
  type        = string
  description = "(Optional) Path to the role. See IAM Identifiers for more information."
  default     = null
}

variable "permissions_boundary" {
  type        = string
  description = "(Optional) ARN of the policy that is used to set the permissions boundary for the role."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A list of tags to apply to the resource."
  default     = {}
}
