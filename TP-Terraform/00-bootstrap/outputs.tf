# output "lock_table_name" {
#   value = aws_dynamodb_table.tf_lock.name
# }

# output "lock_table_arn" {
#   value = aws_dynamodb_table.tf_lock.arn
# }

output "state_folders" {
  value = [for o in aws_s3_object.state_folders : "s3://${o.bucket}/${o.key}"]
}
