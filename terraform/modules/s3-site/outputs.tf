output "site_bucket_name" { value = aws_s3_bucket.site.bucket }
output "site_bucket_arn" { value = aws_s3_bucket.site.arn }
output "logs_bucket_name" { value = aws_s3_bucket.logs.bucket }
output "logs_bucket_arn" { value = aws_s3_bucket.logs.arn }
