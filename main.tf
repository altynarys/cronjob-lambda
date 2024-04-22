data "aws_caller_identity" "current" {}

##################   !!!   S3 with lambda function code in it   !!!   ##################

resource "aws_s3_bucket" "lambda_code" {
    bucket      = "${var.base_name}-lambda-code"
    tags        = merge({App = "${var.base_name}"}, var.main_tags)
}

resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.bucket
  key    = "${var.base_name}-lambda-code.zip"
  source = "${path.module}/lambda-function/myLambdaFunction.zip"
}


##################   !!!   Lambda function   !!!   ##################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_Lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = merge({App = "${var.base_name}"}, var.main_tags)
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 1
}

resource "aws_lambda_function" "lambda_body" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  memory_size   = 128
  package_type  = "Zip"
  runtime       = "python3.12"
  s3_bucket     = aws_s3_bucket.lambda_code.bucket
  s3_key        = aws_s3_object.lambda_code.key
  logging_config {
    log_format  = "Text"
    log_group   = aws_cloudwatch_log_group.lambda.name
  }
  tags          = merge({App = "${var.base_name}"}, var.main_tags)
}


##################   !!!   Cron Job   !!!   ##################

data "aws_iam_policy_document" "assume_scheduler_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_execution" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = ["arn:aws:lambda:*:*:*"]
  }
}

resource "aws_iam_role" "iam_for_eventbridge_scheduler" {
  name               = "iam_for_EventBridge_Scheduler"
  assume_role_policy = data.aws_iam_policy_document.assume_scheduler_role.json
  tags               = merge({App = "${var.base_name}"}, var.main_tags)
}

resource "aws_iam_policy" "lambda_execution" {
  name        = "execution_lambda"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_execution.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.iam_for_eventbridge_scheduler.name
  policy_arn = aws_iam_policy.lambda_execution.arn
}

resource "aws_scheduler_schedule_group" "lambda_execution" {
  name = "lambda_execution"
  tags = merge({App = "${var.base_name}"}, var.main_tags)
}

resource "aws_scheduler_schedule" "lambda_execution" {
  group_name                   = aws_scheduler_schedule_group.lambda_execution.name
  name                         = "lambda_execution_rule"
  schedule_expression          = "rate(5 minutes)"
  flexible_time_window {
    mode                      = "OFF"
  }
  target {
    arn      = aws_lambda_function.lambda_body.arn
    role_arn = aws_iam_role.iam_for_eventbridge_scheduler.arn
    retry_policy {
      maximum_retry_attempts       = 0
    }
  }
}