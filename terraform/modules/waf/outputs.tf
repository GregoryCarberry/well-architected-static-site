output "waf_arn" {
  value = aws_wafv2_web_acl.this.arn
}

output "waf_logs_bucket_arn" {
  value       = aws_s3_bucket.waf_logs.arn
  description = "ARN of the dedicated us-east-1 S3 bucket receiving WAF logs."
}

output "waf_logs_bucket_name" {
  value       = aws_s3_bucket.waf_logs.bucket
  description = "Bucket name for WAF logs (us-east-1)."
}

output "waf_firehose_arn" {
  value       = aws_kinesis_firehose_delivery_stream.waf_logs.arn
  description = "ARN of the us-east-1 Firehose stream for WAF logs."
}
