terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = "bibi-s3-v4"
    key    = "ftstate/backup"
    region = "eu-west-1"
  }
}

provider "aws" {
  profile = "default"
  region = var.aws_region
}

module "royal_cognito" {
  source = "./cognito"
}



resource "random_string" "random" {
  length           = 4
  special          = false
}

resource "aws_dynamodb_table" "movie_table" {
  name           = var.dynamodb_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "year"
  range_key      = "title"

  attribute {
    name = "year"
    type = "N"
  }

  attribute {
    name = "title"
    type = "S"
  }

}

#========================================================================
// lambda setup
#========================================================================

resource "aws_s3_bucket" "lambda_bucket" {
  bucket_prefix = var.s3_bucket_prefix
  force_destroy = true
}

#resource "aws_s3_bucket_acl" "private_bucket" {
#  bucket = aws_s3_bucket.lambda_bucket.id
#  acl    = "public-read-write"
#}

data "archive_file" "lambda_zip" {
  type = "zip"

  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

data "archive_file" "lambda_zip2" {
  type = "zip"

  source_dir  = "${path.module}/src2"
  output_path = "${path.module}/src2.zip"
}

data "archive_file" "lambda_zip3" {
  type = "zip"

  source_dir  = "${path.module}/src3"
  output_path = "${path.module}/src3.zip"
}

data "archive_file" "lambda_zip4" {
  type = "zip"

  source_dir  = "${path.module}/src4"
  output_path = "${path.module}/src4.zip"
}


resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "src.zip"
  source = data.archive_file.lambda_zip.output_path

  etag = filemd5(data.archive_file.lambda_zip.output_path)
}

resource "aws_s3_object" "this2" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "src2.zip"
  source = data.archive_file.lambda_zip2.output_path

  etag = filemd5(data.archive_file.lambda_zip2.output_path)
}

resource "aws_s3_object" "this3" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "src3.zip"
  source = data.archive_file.lambda_zip3.output_path

  etag = filemd5(data.archive_file.lambda_zip3.output_path)
}

resource "aws_s3_object" "this4" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "src4.zip"
  source = data.archive_file.lambda_zip4.output_path

  etag = filemd5(data.archive_file.lambda_zip4.output_path)
}


//Define lambda function
resource "aws_lambda_function" "apigw_lambda_ddb" {
  function_name = "${var.lambda_name}-${random_string.random.id}"
  description = "serverlessland pattern"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.this.key

  runtime = "python3.8"
  handler = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DDB_TABLE = var.dynamodb_table
      SQS_NAME = var.sqs_name
      REGION = var.aws_region
      STATE_MACHINE_ARN = "${aws_sfn_state_machine.sfn_state_machine.arn}"
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_logs]

}


//Define lambda function
resource "aws_lambda_function" "apigw_lambda_ddb_get" {
  function_name = "${var.lambda_get_name}-${random_string.random.id}"
  description = "serverlessland pattern"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.this2.key

  runtime = "python3.8"
  handler = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip2.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DDB_TABLE = var.dynamodb_table
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_get_logs]

}



//Define lambda function
resource "aws_lambda_function" "apigw_lambda_ddb_delete" {
  function_name = "${var.lambda_delete_name}-${random_string.random.id}"
  description   = "serverlessland pattern"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.this3.key

  runtime = "python3.8"
  handler = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip3.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DDB_TABLE = var.dynamodb_table
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_get_logs]
}



//Define lambda function
resource "aws_lambda_function" "apigw_lambda_sqs_dequeue" {
  function_name = "${var.lambda_sqs_name}-${random_string.random.id}"
  description   = "serverlessland pattern"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.this4.key

  runtime = "python3.8"
  handler = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip4.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DDB_TABLE = var.dynamodb_table
      SQS_NAME = var.sqs_name
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_get_logs]
}



resource "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/${var.lambda_name}-${random_string.random.id}"

  retention_in_days = var.lambda_log_retention
}

resource "aws_cloudwatch_log_group" "lambda_get_logs" {
  name = "/aws/lambda/${var.lambda_get_name}-${random_string.random.id}"

  retention_in_days = var.lambda_log_retention
}

resource "aws_cloudwatch_log_group" "lambda_delete_logs" {
  name = "/aws/lambda/${var.lambda_delete_name}-${random_string.random.id}"

  retention_in_days = var.lambda_log_retention
}


resource "aws_cloudwatch_log_group" "lambda_sqs_logs" {
  name = "/aws/lambda/${var.lambda_sqs_name}-${random_string.random.id}"

  retention_in_days = var.lambda_log_retention
}

resource "aws_iam_role" "lambda_exec" {
  name = "LambdaDdbPost"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_exec_role" {
  name = "lambda-tf-pattern-ddb-post"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWrite*",
                "dynamodb:CreateTable",
                "dynamodb:Delete*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/${var.dynamodb_table}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

data "template_file" "gateway_policy" {
  template = file("policies/post-lambda-to-sqs-permission.json")
}

resource "aws_iam_policy" "sqs_policy" {
  name = "lambba-sqs-cloudwatch-policy"

  policy = data.template_file.gateway_policy.rendered
}



resource "aws_iam_role_policy_attachment" "lambda_policy1" {
   role       = aws_iam_role.lambda_exec.name
   policy_arn =aws_iam_policy.lambda_exec_role.arn
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
   role       = aws_iam_role.lambda_exec.name
   policy_arn =aws_iam_policy.sqs_policy.arn
}
#========================================================================
// API Gateway section
#========================================================================
#resource "aws_api_gateway_authorizer" "api_authorizer" {
#  name          = "CognitoUserPoolAuthorizer"
#  type          = "COGNITO_USER_POOLS"
#  rest_api_id   = aws_apigatewayv2_api.http_lambda.id
#  provider_arns = module.royal_cognito.royal_cognito_user_pool_arn
#}


resource "aws_apigatewayv2_authorizer" "auth" {
  api_id           = aws_apigatewayv2_api.http_lambda.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [module.royal_cognito.royal_user_pool_client_id]
    issuer   = "https://${module.royal_cognito.royal_cognito_user_pool_endpoint}"
  }
}


resource "aws_apigatewayv2_api" "http_lambda" {
  name          = "${var.apigw_name}-${random_string.random.id}"
  protocol_type = "HTTP"
  lifecycle {
  create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  depends_on = [aws_cloudwatch_log_group.api_gw]
}

resource "aws_apigatewayv2_integration" "apigw_lambda" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  integration_uri    = aws_lambda_function.apigw_lambda_ddb.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "post" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  route_key = "POST /movies"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}"

  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.auth.id

}



resource "aws_apigatewayv2_integration" "apigw_lambda_get" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  integration_uri    = aws_lambda_function.apigw_lambda_ddb_get.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  route_key = "GET /movies_get"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_get.id}"

  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.auth.id
}


resource "aws_apigatewayv2_integration" "apigw_lambda_delete" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  integration_uri    = aws_lambda_function.apigw_lambda_ddb_delete.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "delete" {
  api_id = aws_apigatewayv2_api.http_lambda.id

  route_key = "DELETE /movies_delete"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_delete.id}"

  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.auth.id
}



resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/vendedlogs/${var.apigw_name}-${random_string.random.id}"

  retention_in_days = var.apigw_log_retention
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apigw_lambda_ddb.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_lambda.execution_arn}/*/*"
}


resource "aws_lambda_permission" "api_gw_get" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apigw_lambda_ddb_get.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_lambda.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_delete" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apigw_lambda_ddb_delete.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_lambda.execution_arn}/*/*"
}


resource "aws_iam_role" "iam_for_sfn" {
  name = "stepFunctionSampleStepFunctionExecutionIAM"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "policy_publish_sns" {
  name        = "stepFunctionSampleSNSInvocationPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "sns:Publish",
              "sns:SetSMSAttributes",
              "sns:GetSMSAttributes"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_policy" "policy_invoke_lambda" {
  name        = "stepFunctionSampleLambdaFunctionInvocationPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "lambda:InvokeAsync"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


// Attach policy to IAM Role for Step Function
resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_invoke_lambda" {
  role       = "${aws_iam_role.iam_for_sfn.name}"
  policy_arn = "${aws_iam_policy.policy_invoke_lambda.arn}"
}

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_publish_sns" {
  role       = "${aws_iam_role.iam_for_sfn.name}"
  policy_arn = "${aws_iam_policy.policy_publish_sns.arn}"
}



// Create state machine for step function
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "sample-state-machine"
  role_arn = "${aws_iam_role.iam_for_sfn.arn}"

  definition = <<EOF

{
  "StartAt": "get items from db",
  "States": {

    "get items from db": {
    "Comment": "get items from DB.",
    "Type": "Task",
    "InputPath": "$",
    "ResultPath": "$",
    "Resource": "arn:aws:states:::lambda:invoke",
    "Parameters": {
    "FunctionName": "${aws_lambda_function.apigw_lambda_ddb_get.arn}",
    "Payload.$": "$"
    },
    "Next": "delete item"
    },

    "delete item": {
    "Comment": "delete item from DB",
    "Type": "Task",
    "InputPath": "$",
    "ResultPath": "$",
    "Resource": "arn:aws:states:::lambda:invoke",
    "Parameters": {
    "FunctionName": "${aws_lambda_function.apigw_lambda_ddb_delete.arn}",
    "Payload.$": "$"
    },
    "End": true
    }



  }
}
EOF

  //depends_on = [aws_lambda_function.apigw_lambda_ddb, aws_lambda_function.apigw_lambda_ddb_get, aws_lambda_function.apigw_lambda_ddb_delete, aws_lambda_function.apigw_lambda_sqs_dequeue]

}
