provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "lighthouse-tester" {
  function_name = "lighthouse-tester"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "aws-lighthouse"
  s3_key    = "v25.zip"

  handler = "index.handler"
  memory_size = "1600"

  timeout = "60"

  runtime = "nodejs8.10"

  role = "${aws_iam_role.lighthouse-tester-api.arn}"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = ["arn:aws:s3:::aws-lighthouse/*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "lighthouse-tester-policy"
  description = "Allow to put reports to s3 bucket"
  policy      = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = "${aws_iam_role.lighthouse-tester-api.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

resource "aws_iam_role" "lighthouse-tester-api" {
  name = "lighthouse-tester-api"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "lighthouse-tester-api" {
  name        = "lighthouse-tester-api"
  description = "Lighthouse Tester API Endpoint"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.lighthouse-tester-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.lighthouse-tester-api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.lighthouse-tester-api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.lighthouse-tester-api.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lighthouse-tester.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.lighthouse-tester-api.id}"
  resource_id   = "${aws_api_gateway_rest_api.lighthouse-tester-api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.lighthouse-tester-api.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lighthouse-tester.invoke_arn}"
}

resource "aws_api_gateway_deployment" "lighthouse-tester-api" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.lighthouse-tester-api.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lighthouse-tester.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.lighthouse-tester-api.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.lighthouse-tester-api.invoke_url}"
}
