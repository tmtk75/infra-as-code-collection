data aws_caller_identity current {}

resource aws_iam_role basicexec {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.sts_assume_lambda.json
}

data aws_iam_policy_document sts_assume_lambda {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    //condition {
    //  test     = "StringEquals"
    //  variable = "sts:ExternalId"
    //  values   = [data.aws_caller_identity.current.account_id]
    //}
		// The above condition causes the next error when creating.
		// Error: Error creating Lambda function: InvalidParameterValueException: The role defined for the function cannot be assumed by Lambda.
  }
}

resource aws_iam_role_policy_attachment basicexec {
  role       = aws_iam_role.basicexec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
