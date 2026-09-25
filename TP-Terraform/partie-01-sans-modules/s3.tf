############################################################
# S3 : deux buckets sécurisés (aucun usage applicatif)
############################################################
resource "random_id" "bucket_suffix" {
  byte_length = 4 # noms S3 uniques au niveau mondial
}

resource "aws_s3_bucket" "this" {
  for_each = toset(var.s3_bucket_ids)

  bucket        = "${local.bucket_prefix}-s3-${each.key}-${random_id.bucket_suffix.hex}"
  force_destroy = true # TP : permet le destroy même si le bucket contient des objets

  tags = {
    Name = "${local.prefix}_s3_${each.key}"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced" # ACL désactivées
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "s3_tls_only" {
  for_each = aws_s3_bucket.this

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  policy = data.aws_iam_policy_document.s3_tls_only[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
