
data "aws_partition" "current" {}
data "aws_elb_service_account" "current" {}

####################################################
# load balancer
####################################################

resource "aws_lb" "this" {
  count                            = var.create ? 1 : 0
  client_keep_alive                = var.client_keep_alive
  customer_owned_ipv4_pool         = var.customer_owned_ipv4_pool
  desync_mitigation_mode           = var.desync_mitigation_mode
  dns_record_client_routing_policy = var.dns_record_client_routing_policy
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_xff_client_port           = var.enable_xff_client_port
  enable_waf_fail_open             = var.enable_waf_fail_open
  enable_zonal_shift               = var.enable_zonal_shift
  idle_timeout                     = var.idle_timeout
  internal                         = var.internal
  ip_address_type                  = var.ip_address_type
  load_balancer_type               = var.load_balancer_type
  name                             = var.name
  name_prefix                      = var.name_prefix
  security_groups                  = var.security_group_ids
  preserve_host_header             = var.preserve_host_header

  enable_tls_version_and_cipher_suite_headers                  = var.enable_tls_version_and_cipher_suite_headers
  enforce_security_group_inbound_rules_on_private_link_traffic = var.enforce_security_group_inbound_rules_on_private_link_traffic

  dynamic "access_logs" {
    for_each = length(var.access_logs) > 0 ? [var.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      enabled = try(access_logs.value.enabled, null)
      prefix  = try(access_logs.value.prefix, null)
    }
  }

  dynamic "connection_logs" {
    for_each = length(var.connection_logs) > 0 ? [var.connection_logs] : []
    content {
      bucket  = connection_logs.value.bucket
      enabled = try(connection_logs.value.enabled, false)
      prefix  = try(connection_logs.value.prefix, "")
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
    }
  }

  subnets                    = var.subnets
  tags                       = var.tags
  xff_header_processing_mode = var.xff_header_processing_mode

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  lifecycle {
    ignore_changes = [
      tags["elasticbeanstalk:shared-elb-environment-count"]
    ]
  }
}

resource "aws_lb_listener" "this" {
  for_each = { for v in var.listeners : v.name => v }

  alpn_policy              = try(each.value.alpn_policy, null)
  certificate_arn          = try(each.value.certificate_arn, null)
  port                     = each.value.port
  protocol                 = each.value.protocol
  load_balancer_arn        = var.create ? aws_lb.this[0].arn : each.value.load_balancer_arn
  ssl_policy               = try(each.value.ssl_policy, null)
  tcp_idle_timeout_seconds = try(each.value.tcp_idle_timeout_seconds, null)
  tags                     = var.tags

  dynamic "default_action" {
    for_each = try(each.value.authenticate_cognito.default ? [each.value.authenticate_cognito] : [], [])
    content {
      order = try(default_action.value.order, null)
      type  = "authenticate-cognito"
      authenticate_cognito {
        user_pool_arn                       = default_action.value.user_pool_arn
        user_pool_client_id                 = default_action.value.user_pool_client_id
        user_pool_domain                    = default_action.value.user_pool_domain
        authentication_request_extra_params = try(default_action.value.authentication_request_extra_params, null)
        on_unauthenticated_request          = try(default_action.value.on_unauthenticated_request, null)
        scope                               = try(default_action.value.scope, null)
        session_cookie_name                 = try(default_action.value.session_cookie_name, null)
        session_timeout                     = try(default_action.value.session_timeout, null)
      }
    }
  }
  dynamic "default_action" {
    for_each = try(each.value.authenticate_oidc.default ? [each.value.authenticate_oidc] : [], [])
    content {
      order = try(default_action.value.order, null)
      type  = "authenticate-oidc"
      authenticate_oidc {
        authorization_endpoint              = default_action.value.authorization_endpoint
        client_id                           = default_action.value.client_id
        client_secret                       = default_action.value.client_secret
        issuer                              = default_action.value.issuer
        token_endpoint                      = default_action.value.token_endpoint
        user_info_endpoint                  = default_action.value.user_info_endpoint
        authentication_request_extra_params = try(default_action.value.authentication_request_extra_params, null)
        on_unauthenticated_request          = try(default_action.value.on_unauthenticated_request, null)
        scope                               = try(default_action.value.scope, null)
        session_cookie_name                 = try(default_action.value.session_cookie_name, null)
        session_timeout                     = try(default_action.value.session_timeout, null)
      }
    }
  }
  dynamic "default_action" {
    for_each = try(each.value.fixed_response.default ? [each.value.fixed_response] : [], [])
    content {
      order = try(default_action.value.order, null)
      type  = "fixed-response"
      fixed_response {
        content_type = default_action.value.content_type
        message_body = try(default_action.value.message_body, null)
        status_code  = try(default_action.value.status_code, null)
      }
    }
  }
  dynamic "default_action" {
    for_each = try(each.value.forward.default ? [each.value.forward] : [], [])
    content {
      order            = try(default_action.value.order, null)
      type             = "forward"
      target_group_arn = try(aws_lb_target_group.this[default_action.value.target_group].arn, null)
      dynamic "forward" {
        for_each = var.load_balancer_type == "application" ? try([default_action.value.forward], []) : []
        content {
          dynamic "target_group" {
            for_each = try(default_action.value.target_groups, [])
            content {
              arn    = try(target_group.value.arn, aws_lb_target_group.this[target_group.value.name].arn)
              weight = try(target_group.value.weight, null)
            }
          }
        }
      }
    }
  }
  dynamic "default_action" {
    for_each = try(each.value.redirect.default ? [each.value.redirect] : [], [])
    content {
      order = try(default_action.value.order, null)
      type  = "redirect"
      redirect {
        host        = try(default_action.value.host, null)
        path        = try(default_action.value.path, null)
        port        = try(default_action.value.port, null)
        protocol    = try(default_action.value.protocol, null)
        query       = try(default_action.value.query, null)
        status_code = default_action.value.status_code
      }
    }
  }
  dynamic "mutual_authentication" {
    for_each = { for v in try([each.value.mutual_authentication.0], []) : v.mode => v if v.mode != null }
    content {
      mode                             = mutual_authentication.value.mode
      trust_store_arn                  = try(mutual_authentication.value.trust_store_arn, null)
      ignore_client_certificate_expiry = try(mutual_authentication.value.ignore_client_certificate_expiry, null)
    }
  }
}

/*
####################################################
# certificates
####################################################

locals {
  # Take the list of `additional_certificate_arns` from the listener and create
  # a map entry that maps each certificate to the listener key. This map of maps
  # is then used to create the certificate resources.
  additional_certs = merge(values({
    for listener_key, listener_values in var.listeners : listener_key =>
    {
      # This will cause certs to be detached and reattached if certificate_arns
      # towards the front of the list are updated/removed. However, we need to have
      # unique keys on the resulting map and we can't have computed values (i.e. cert ARN)
      # in the key so we are using the array index as part of the key.
      for idx, cert_arn in lookup(listener_values, "additional_certificate_arns", []) :
      "${listener_key}/${idx}" => {
        listener_key    = listener_key
        certificate_arn = cert_arn
      }
    } if length(lookup(listener_values, "additional_certificate_arns", [])) > 0
  })...)
}

resource "aws_lb_listener_certificate" "this" {
  for_each = local.additional_certs

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}*/

####################################################
# target groups
####################################################

resource "aws_lb_target_group" "this" {
  for_each = { for v in var.target_groups : v.name => v }

  name                               = each.value.name
  name_prefix                        = each.value.name_prefix
  connection_termination             = each.value.connection_termination
  deregistration_delay               = each.value.deregistration_delay
  lambda_multi_value_headers_enabled = each.value.lambda_multi_value_headers_enabled
  load_balancing_algorithm_type      = each.value.load_balancing_algorithm_type
  load_balancing_anomaly_mitigation  = each.value.load_balancing_anomaly_mitigation
  load_balancing_cross_zone_enabled  = each.value.load_balancing_cross_zone_enabled
  port                               = each.value.port
  preserve_client_ip                 = each.value.preserve_client_ip
  protocol_version                   = each.value.protocol_version
  protocol                           = each.value.protocol
  proxy_protocol_v2                  = each.value.proxy_protocol_v2
  slow_start                         = each.value.slow_start
  target_type                        = each.value.target.type
  ip_address_type                    = each.value.ip_address_type
  vpc_id                             = each.value.vpc_id

  tags = merge(
    { Name = each.key },
    var.tags,
    each.value.tags
  )

  dynamic "health_check" {
    for_each = try([each.value.health_check], [])
    content {
      enabled             = health_check.value.enabled
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  dynamic "stickiness" {
    for_each = try(each.value.stickiness.enabled ? [each.value.stickiness] : [], [])
    content {
      cookie_duration = try(stickiness.value.cookie_duration, null)
      cookie_name     = try(stickiness.value.cookie_name, null)
      enabled         = try(stickiness.value.enabled, true)
      type            = var.load_balancer_type == "network" ? "source_ip" : stickiness.value.type
    }
  }

  dynamic "target_failover" {
    for_each = var.load_balancer_type == "network" ? try([each.value.target_failover], []) : []
    content {
      on_deregistration = try(target_failover.value.on_deregistration, null)
      on_unhealthy      = try(target_failover.value.on_unhealthy, null)
    }
  }

  dynamic "target_health_state" {
    for_each = var.load_balancer_type == "network" ? try([each.value.target_health_state], []) : []
    content {
      enable_unhealthy_connection_termination = try(target_health_state.value.enable_unhealthy_connection_termination, true)
      unhealthy_draining_interval             = try(target_health_state.value.unhealthy_draining_interval, null)
    }
  }

  dynamic "target_group_health" {
    for_each = try([each.value.target_group_health], [])
    content {
      dynamic "dns_failover" {
        for_each = try([target_group_health.value.dns_failover], [])
        content {
          minimum_healthy_targets_count      = try(dns_failover.value.minimum_healthy_targets_count, null)
          minimum_healthy_targets_percentage = try(dns_failover.value.minimum_healthy_targets_percentage, null)
        }
      }
      dynamic "unhealthy_state_routing" {
        for_each = try([target_group_health.value.unhealthy_state_routing], [])

        content {
          minimum_healthy_targets_count      = try(unhealthy_state_routing.value.minimum_healthy_targets_count, null)
          minimum_healthy_targets_percentage = try(unhealthy_state_routing.value.minimum_healthy_targets_percentage, null)
        }
      }
    }
  }

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [
      target_failover,
    ]
  }
}

####################################################
# Target Group Attachment
####################################################

resource "aws_lb_target_group_attachment" "this" {
  for_each          = { for v in var.target_groups : v.name => v }
  target_group_arn  = aws_lb_target_group.this[each.key].arn
  target_id         = each.value.target.id
  port              = each.value.target.port
  availability_zone = each.value.target.availability_zone
}

####################################################
# service endpoints
####################################################

resource "aws_vpc_endpoint_service" "this" {
  count = var.endpoint_service.enabled ? 1 : 0

  acceptance_required        = var.endpoint_service.acceptance_required
  allowed_principals         = var.endpoint_service.allowed_principals
  gateway_load_balancer_arns = var.endpoint_service.gateway_load_balancer_arns
  network_load_balancer_arns = [aws_lb.this[0].arn, ]
  private_dns_name           = var.endpoint_service.private_dns_name
  supported_ip_address_types = var.endpoint_service.dualstack ? ["ipv4", "ipv6"] : ["ipv4"]

  tags = merge(
    var.tags,
    var.endpoint_service.tags
  )
}

####################################################
# route53 records
####################################################

resource "aws_route53_record" "this" {
  for_each = { for v in var.route53_records : v.name => v }
  zone_id  = each.value.zone_id
  name     = each.value.name
  type     = each.value.type

  alias {
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
    evaluate_target_health = true
  }
}

####################################################
# waf
####################################################

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.associate_web_acl ? 1 : 0
  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = var.web_acl_arn
}

####################################################
# bucket access policy
####################################################

# access logs

# data "aws_s3_bucket" "access_logs" {
#   count  = var.access_logs.enabled ? 1 : 0
#   bucket = aws_lb.this[0].access_logs[0].bucket
# }

# data "aws_iam_policy_document" "access_logs" {
#   count = var.access_logs.enabled ? 1 : 0
#   statement {
#     effect  = "Allow"
#     actions = ["s3:PutObject"]
#     principals {
#       type        = "AWS"
#       identifiers = [data.aws_elb_service_account.current.arn]
#     }
#     resources = [
#       "${data.aws_s3_bucket.access_logs[0].arn}/*",
#     ]
#   }
# }

# resource "aws_s3_bucket_policy" "access_logs" {
#   count  = var.access_logs.enabled ? 1 : 0
#   bucket = aws_lb.this[0].access_logs[0].bucket
#   policy = data.aws_iam_policy_document.access_logs[0].json
# }
