output "bucket_id" {
  value       = aws_s3_bucket.s3_bucket.id
  description = "The name of the bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.s3_bucket.arn
  description = <<-EOT
    The ARN of the bucket. Will be of format arn:aws:s3:::bucketname.
  EOT
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.s3_bucket.bucket_domain_name
  description = <<-EOT
    The bucket domain name. Will be of format bucketname.s3.amazonaws.com.
  EOT
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
  description = <<-EOT
    The bucket region-specific domain name.
    The bucket domain name including the region name,
    please refer here for format.
    Note:
    The AWS CloudFront allows specifying S3 region-specific endpoint
    when creating S3 origin, it will prevent redirect issues from
    CloudFront to S3 Origin URL.
  EOT
}

output "hosted_zone_id" {
  value       = aws_s3_bucket.s3_bucket.hosted_zone_id
  description = "The Route 53 Hosted Zone ID for this bucket's region."
}

output "region" {
  value       = aws_s3_bucket.s3_bucket.region
  description = "The AWS region this bucket resides in."
}

output "tags_all" {
  value       = aws_s3_bucket.s3_bucket.tags_all
  description = <<-EOT
    A map of tags assigned to the resource, including those inherited
    from the aws provider's default_tags configuration block.
  EOT
}

output "s3_bucket_policy" {
  value       = data.aws_iam_policy_document.bucket_policy.json
  description = <<-EOT
    The s3_bucket_policy document, which is attached to the S3 bucket.
  EOT
}

output "kms_master_key_id" {
  description = "KMS CMK ID used by the S3 bucket (if any)"
  value       = var.kms_master_key_id
}