data "aws_iam_policy_document" "trust_policy" {

  dynamic "statement" {
    for_each = { for index, value in var.identities : index => value }
    content {
      sid     = statement.value.sid
      actions = ["sts:AssumeRole"]
      dynamic "principals" {
        for_each = {
          for index, value in statement.value.principals : index => value
        }
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      dynamic "condition" {
        for_each = {
          for index, value in statement.value.conditions : index => value
        }
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }

  dynamic "statement" {
    for_each = { for index, value in var.web_identities : index => value }
    content {
      sid     = statement.value.sid
      actions = ["sts:AssumeRoleWithWebIdentity"]
      dynamic "principals" {
        for_each = {
          for index, value in statement.value.principals : index => value
        }
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      dynamic "condition" {
        for_each = {
          for index, value in statement.value.conditions : index => value
        }
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }

  dynamic "statement" {
    for_each = { for index, value in var.saml_identities : index => value }
    content {
      sid     = statement.value.sid
      actions = ["sts:AssumeRoleWithSAML"]
      dynamic "principals" {
        for_each = { for index, value in statement.value.principals : index => value }
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      dynamic "condition" {
        for_each = { for index, value in statement.value.conditions : index => value }
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "iam_role" {
  name_prefix           = var.name_prefix
  name                  = var.name_prefix != null ? null : var.name
  description           = var.description
  force_detach_policies = var.force_detach_policies
  max_session_duration  = var.max_session_duration
  path                  = var.path
  permissions_boundary  = var.permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.trust_policy.json
  tags                  = var.tags
}

# Replacement for the deprecated inline_policy argument in the aws_iam_role resource
# !!! The condition used in the count argument must be 'static' enough for terraform plan to work.
# Interestingly, the condition <string> != null did not function correctly in complex setups
# (e.g., script calls module, that calls iam_role module), whereas <object> != null worked as expected.
# To address this, the variable 'inline_policy' was converted from a string to an object.
resource "aws_iam_role_policy" "inline_policy" {
  count  = var.inline_policy != null ? 1 : 0
  name   = var.inline_policy.name
  role   = aws_iam_role.iam_role.id
  policy = var.inline_policy.json
}

# this resource takes exclusive ownership over inline policies assigned to a role
resource "aws_iam_role_policies_exclusive" "inline_policy" {
  count        = var.exclusive_mgmt_of_inline_policy ? 1 : 0
  role_name    = aws_iam_role.iam_role.name
  policy_names = try([aws_iam_role_policy.inline_policy[0].name], [])
}

# Replacement for the deprecated managed_policy_arns argument in the aws_iam_role resource
resource "aws_iam_role_policy_attachment" "managed_policy_arns" {
  for_each   = { for v in coalesce(var.managed_policy_arns, []) : v.name => v.arn }
  role       = aws_iam_role.iam_role.id
  policy_arn = each.value
}

# this resource takes exclusive ownership over managed IAM policies attached to a role
resource "aws_iam_role_policy_attachments_exclusive" "managed_policy_arns" {
  count       = var.exclusive_mgmt_of_managed_policy_arns ? 1 : 0
  role_name   = aws_iam_role.iam_role.name
  policy_arns = try(var.managed_policy_arns[*].arn, [])
}