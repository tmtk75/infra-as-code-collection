provider aws {
  profile = var.aws_profile
  region  = var.aws_region
}

resource aws_s3_bucket dest {
  bucket = "${var.prefix}-firehose-dest"
}

data archive_file lambda {
  type        = "zip"
  source_dir  = "./bin"
  output_path = "./lambda.zip"
}

locals {
  funcs = {
    hello     = { timeout : 3 }
    processor = { timeout : 60 }
  }
}

resource aws_lambda_function funcs {
  for_each         = local.funcs
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.prefix}-${each.key}"
  handler          = "./${each.key}"
  role             = module.lambda_role.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = each.value.timeout
}

resource aws_lambda_permission to_s3 {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.funcs["processor"].function_name
  principal     = "firehose.amazonaws.com"
  source_arn    = aws_kinesis_firehose_delivery_stream.to_s3.arn
}

resource aws_kinesis_firehose_delivery_stream to_s3 {
  name        = "${var.prefix}-hello"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = module.firehose_s3_role.arn
    bucket_arn         = aws_s3_bucket.dest.arn
    buffer_interval    = 60 # seconds
    compression_format = "GZIP"

    processing_configuration {
      enabled = true
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.funcs["processor"].arn}:$LATEST"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${var.prefix}-to_s3"
      log_stream_name = "latest" # any
    }
  }
}

resource aws_cloudwatch_log_subscription_filter to_s3 {
  name            = "${var.prefix}-to_s3"
  log_group_name  = aws_cloudwatch_log_group.source.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.to_s3.arn
  role_arn        = module.subscription_filter_role.arn
}

resource aws_cloudwatch_log_group source {
  name = "/aws/lambda/${aws_lambda_function.funcs["hello"].function_name}"
}

module lambda_role {
  source    = "./modules/lambda-role"
  role_name = "${var.prefix}-basic-execution"
}

module firehose_s3_role {
  source               = "./modules/firehose_s3-role"
  role_name            = "${var.prefix}-firehose_s3"
  destination_s3_arn   = aws_s3_bucket.dest.arn
  processor_lambda_arn = aws_lambda_function.funcs["processor"].arn
}

module subscription_filter_role {
  source           = "./modules/subscription_filter-role"
  role_name        = "${var.prefix}-subscription_filter"
  destination_arns = [aws_kinesis_firehose_delivery_stream.to_s3.arn]
}
