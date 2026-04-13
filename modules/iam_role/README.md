<!-- BEGIN_TF_DOCS -->
<!-- THE CONTENT OF THIS FILE IS GENERATED -->
# A Terraform module to create an AWS IAM role

This module can be used to provision an AWS IAM role.

### Additional resources
- [Terraform Resource aws\_iam\_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [Terraform Data Source aws\_iam\_policy\_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)
- [AWS Identity and Access Management User Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)
- [Policies and permissions in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [Managing IAM policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage.html)

---

## How to use this module

This module is intended to be used as a part of an infrastructure module composition.

Define the AWS provider in your main module, then add the following module block:

```terraform
module "aws_iam_role" {
  # where to find the source code for the child module
  source = "../modules/iam_role"

  # set the variables

  # choose between name_prefix or name, if you provide both, name_prefix will overwrite name
  name_prefix           = "test_role_name_prefix"
  name                  = "test_role"
  description           = "Description of the role"
  force_detach_policies = false

  # in case you want to add an inline policy
  inline_policy      = {
    name = "my_inline_policy"
    json = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = [
            "ec2:Describe*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
  # instructs Terraform to ignore all inline policy assignments not explicitly defined in this configuration
  # (default value of this parameter is true => Terraform removes all inline policy assignments, that are not managed by this script)
  exclusive_mgmt_of_inline_policy = false

  # in case you want to attach a policy resource to the role
  managed_policy_arns = [
    {
      name = "policy_one",
      arn  = aws_iam_policy.policy_one.arn
    },
    {
      name = "policy_two",
      arn  = aws_iam_policy.policy_two.arn
    }
  ]
  # instructs Terraform to ignore all managed policy assignments not explicitly defined in this configuration
  # (default value of this parameter is true => Terraform removes all managed policy assignments, that are not managed by this script)
  exclusive_mgmt_of_managed_policy_arns = false

  max_session_duration = 3600
  path                 = "/division_abc/subdivision_xyz/product_1234/engineering/"
  permissions_boundary = "aws_iam_policy.boundary_policy_one.arn"

  # this variable creates the entities entitled to use this role via "sts:AssumeRole". Every sid and conditions set only applies to the principals
  # within the same list entry (in this example the conditions StringEquals and StringEqualsIgnoreCase belong to the TestSid1 statement, but not to TestSid2.
  identities = [
    {
      sid        = "TestSid1"
      principals = [
        {
          type        = "AWS"
          identifiers = [
            "arn:aws:iam::1234568:role/test-iam-role"
          ]
        }
      ],
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:username"
          values   = [
            "example-name-1",
            "example-name-2"
          ]
        },
        {
          test     = "StringEqualsIgnoreCase"
          variable = "aws:username"
          values   = [
            "example-name-3"
          ]
        }
      ]
    },
    {
      sid        = "TestSid2"
      principals = [
        {
          type        = "Service"
          identifiers = [
            "ec2.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      ]
    }
  ]

  # if you want to rely on "sts:AssumeRoleWithWebIdentity", use web_identities instead of identities
  web_identities = [
    {
      sid        = "TestSid1"
      principals = [
        {
          type        = "Federated"
          identifiers = [
            "arn:aws:iam::<1234567890>:oidc-provider/12345678"
          ]
        }
      ]
    }
  ]

  # or the same with "sts:AssumeRoleWithSAML" instead
  saml_identities = [
    {
      sid = "TestSid1"
      principals = [
        {
          type        = "Federated"
          identifiers = ["arn:aws:iam::<1234567890>:oidc-provider/12345678"]
        }
      ]
    }
  ]

  tags = {
    "key1" = "value1",
    "key2" = "value2",
  }
}
```

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
| [aws_iam_role.iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policies_exclusive.inline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policies_exclusive) | resource |
| [aws_iam_role_policy.inline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.managed_policy_arns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachments_exclusive.managed_policy_arns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachments_exclusive) | resource |
| [aws_iam_policy_document.trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| description | (Optional) Description of the role. | `null` | no |
| exclusive\_mgmt\_of\_inline\_policy | (Optional) Whether Terraform should exclusively manage inline policy associations.     This includes removal of inline policies which are not explicitly configured here. | `true` | no |
| exclusive\_mgmt\_of\_managed\_policy\_arns | (Optional) Whether Terraform should exclusively manage all managed policy attachments.     This includes removal of managed IAM policies which are not explicitly configured here. | `true` | no |
| force\_detach\_policies | (Optional) Whether to force detaching any policies the role has before destroying it. Defaults to false. | `false` | no |
| identities | List of entities who are entitled to use this role via 'sts:AssumeRole'. | `[]` | no |
| inline\_policy | (Optional) Inline policy to assign to the role. Policy document should be provided in the 'json' attribute     as a JSON-formatted string. For more information about building IAM policy documents with Terraform,     see the AWS IAM Policy Document Guide. | `null` | no |
| managed\_policy\_arns | (Optional) Set of IAM managed policy ARNs to attach to the IAM role.     When configured and exclusive\_mgmt\_of\_managed\_policy\_arns = true, Terraform will align the role's managed policy     attachments with this set by attaching or detaching managed policies. If exclusive\_mgmt\_of\_managed\_policy\_arns = false,      then Terraform will add the configured managed\_policy\_arns without removing any existing policy attachments,     that are not managed by Terraform.     If this attribute is not configured and exclusive\_mgmt\_of\_managed\_policy\_arns is set to false, Terraform will     ignore policy attachments to this resource. However, if exclusive\_mgmt\_of\_managed\_policy\_arns is set to true,      Terraform will remove all managed policy attachments. | `null` | no |
| max\_session\_duration | (Optional) Maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting,     the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours. | `3600` | no |
| name | (Optional, Forces new resource) Friendly name of the role. If omitted, Terraform will assign a random, unique name.     See IAM Identifiers for more information.     If both name and name\_prefix are provided, name\_prefix has the higher priority and will overwrite name. | `null` | no |
| name\_prefix | (Optional, Forces new resource) Creates a unique friendly name beginning with the specified prefix.     If both name and name\_prefix are provided, name\_prefix has the higher priority and will overwrite name. | `null` | no |
| path | (Optional) Path to the role. See IAM Identifiers for more information. | `null` | no |
| permissions\_boundary | (Optional) ARN of the policy that is used to set the permissions boundary for the role. | `null` | no |
| saml\_identities | List of entities who are entitled to use this role via 'sts:AssumeRoleWithSAML'. | `[]` | no |
| tags | A list of tags to apply to the resource. | `{}` | no |
| web\_identities | List of entities who are entitled to use this role via 'sts:AssumeRoleWithWebIdentity'. | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | Amazon Resource Name (ARN) specifying the role. |
| create\_date | Creation date of the IAM role. |
| id | Name of the role. |
| tags\_all | A map of tags assigned to the resource, including those inherited from the aws provider default\_tags configuration block. |
| unique\_id | Stable and unique string identifying the role. |
<!-- END_TF_DOCS -->
