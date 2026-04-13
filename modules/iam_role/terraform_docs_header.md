# A Terraform module to create an AWS IAM role

This module can be used to provision an AWS IAM role. 

### Additional resources
- [Terraform Resource aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [Terraform Data Source aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)
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
