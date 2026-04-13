output "arn" {
  value       = aws_iam_role.iam_role.arn
  description = "Amazon Resource Name (ARN) specifying the role."
}

output "create_date" {
  value       = aws_iam_role.iam_role.create_date
  description = "Creation date of the IAM role."
}

output "id" {
  value       = aws_iam_role.iam_role.id
  description = "Name of the role."
}

output "tags_all" {
  value       = aws_iam_role.iam_role.tags_all
  description = "A map of tags assigned to the resource, including those inherited from the aws provider default_tags configuration block."
}

output "unique_id" {
  value       = aws_iam_role.iam_role.unique_id
  description = "Stable and unique string identifying the role."
}
