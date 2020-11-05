data aws_caller_identity current {}
data aws_region current {}

/* Role for subscription filter */
resource aws_iam_role subscription_filter {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.subscription_filter.json
}

data aws_iam_policy_document subscription_filter {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
		#condition {
    #  test     = "StringEquals"
    #  variable = "sts:ExternalId"
    #  values   = [data.aws_caller_identity.current.account_id]
    #}
  }
}

resource aws_iam_role_policy subscription_filter {
  name   = "${var.role_name}-subscription_filter"
  role   = aws_iam_role.subscription_filter.id
  policy = data.aws_iam_policy_document.backup_assume_role.json
}

data aws_iam_policy_document backup_assume_role {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = var.destination_arns
  }
}

