# API Gateway
resource "aws_apigatewayv2_api" "this" {
  for_each = {for o in var.names : o.name => o if var.create && var.create_api_gateway}
  name          = each.value.name
  description   = each.value.description
  protocol_type = each.value.protocol_type
  version       = each.value.api_version
  body          = each.value.body

  route_selection_expression   = var.route_selection_expression
  api_key_selection_expression = var.api_key_selection_expression
  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  /* Start of quick create */
  route_key       = var.route_key
  credentials_arn = var.credentials_arn
  target          = var.target
  /* End of quick create */

  tags = var.tags
}

locals {
  product_api = [for api in aws_apigatewayv2_api.this : api.id if api.name == "RinggitPay.Products.API"]
  portal_api = [for api in aws_apigatewayv2_api.this : api.id if api.name == "RinggitPay.Portal.API"]
}


# Domain name

resource "aws_apigatewayv2_domain_name" "product-domain" {
  #  count = var.create && var.create_api_domain_name ? 1 : 0

  domain_name = var.product_domain_name

  domain_name_configuration {
    certificate_arn                        = var.product_domain_name_certificate_arn
    ownership_verification_certificate_arn = var.domain_name_ownership_verification_certificate_arn
    endpoint_type                          = "REGIONAL"
    security_policy                        = "TLS_1_2"
  }

  tags = merge(var.domain_name_tags, var.tags)
}


resource "aws_apigatewayv2_domain_name" "portal-domain" {
#  count = var.create && var.create_api_domain_name ? 1 : 0

  domain_name = var.portal_domain_name

  domain_name_configuration {
    certificate_arn                        = var.portal_domain_name_certificate_arn
    ownership_verification_certificate_arn = var.domain_name_ownership_verification_certificate_arn
    endpoint_type                          = "REGIONAL"
    security_policy                        = "TLS_1_2"
  }


  tags = merge(var.domain_name_tags, var.tags)
}



# Default stage

resource "aws_apigatewayv2_stage" "product-stage" {


  api_id      = local.product_api[0]
  name        = var.stage_name
  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.default_stage_access_log_destination_arn != null && var.default_stage_access_log_format != null ? [true] : []

    content {
      destination_arn = var.default_stage_access_log_destination_arn
      format          = var.default_stage_access_log_format
    }
  }


  tags = merge(var.default_stage_tags, var.tags)

  # Bug in terraform-aws-provider with perpetual diff
  lifecycle {
    ignore_changes = [deployment_id]
  }
}


resource "aws_apigatewayv2_stage" "portal-stage" {


  api_id      = local.portal_api[0]
  name        = var.stage_name
  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.default_stage_access_log_destination_arn != null && var.default_stage_access_log_format != null ? [true] : []

    content {
      destination_arn = var.default_stage_access_log_destination_arn
      format          = var.default_stage_access_log_format
    }
  }

  tags = merge(var.default_stage_tags, var.tags)

  # Bug in terraform-aws-provider with perpetual diff
  lifecycle {
    ignore_changes = [deployment_id]
  }
}



resource "aws_apigatewayv2_api_mapping" "product_api_mapping" {
  api_id      = local.product_api[0]
  domain_name = aws_apigatewayv2_domain_name.product-domain.domain_name
  stage       = aws_apigatewayv2_stage.product-stage.id
}

resource "aws_apigatewayv2_api_mapping" "portal_api_mapping" {
  api_id      = local.portal_api[0]
  domain_name = aws_apigatewayv2_domain_name.portal-domain.domain_name
  stage       = aws_apigatewayv2_stage.portal-stage.id
}

