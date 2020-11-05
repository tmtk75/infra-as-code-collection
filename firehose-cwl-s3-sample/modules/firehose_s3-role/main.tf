data aws_caller_identity current {}

/* Role for firehose */
resource aws_iam_role firehose_s3 {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

data aws_iam_policy_document firehose_assume_role {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

/* Policy for destination */
resource aws_iam_role_policy firehose_s3 {
  name   = "${var.role_name}-filrhose"
  role   = aws_iam_role.firehose_s3.id
  policy = data.aws_iam_policy_document.firehose_role.json
}

data aws_iam_policy_document firehose_role {
  statement {
    effect = "Allow"
    actions = [ "s3:*" ]
    resources = [
			var.destination_s3_arn,
      "${var.destination_s3_arn}/*"
		]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:*"]
    resources = ["*"]
		// TODO: var.processor_lambda_arn
  }
}

