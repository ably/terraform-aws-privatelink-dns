resource "aws_route53_record" "ably-global" {
  for_each        = toset(var.regions)
  zone_id         = var.route53_private_zone_id
  name            = var.dns_global_record
  health_check_id = aws_route53_health_check.privatelink_disabled_status[each.key].id

  latency_routing_policy {
    region = each.key
  }

  set_identifier = each.key

  type = "A"

  alias {
    name                   = var.ably_vpc_endpoint_dns_entry
    zone_id                = var.ably_vpc_endpoint_dns_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ably-regional" {
  for_each = toset(var.regions)
  zone_id  = var.route53_private_zone_id
  name     = "${each.key}.${var.dns_global_record}"
  type     = "CNAME"
  ttl      = var.dns_regional_record_ttl
  records  = [var.ably_vpc_endpoint_dns_entry]
}

resource "aws_route53_record" "ably-zonal" {
  for_each = toset(var.azs)
  zone_id  = var.route53_private_zone_id
  name     = "${each.key}.${var.dns_global_record}"
  type     = "CNAME"
  ttl      = var.dns_zonal_record_ttl
  records  = [replace(var.ably_vpc_endpoint_dns_entry, "/^([\\w-]+).(.*)$/", "$1-${each.key}.$2")]
}

resource "aws_cloudwatch_metric_alarm" "privatelink_disabled_status" {
  for_each            = toset(var.regions)
  alarm_name          = "ably-privatelink-region-status-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Health"
  namespace           = "Ably/VPCEndpoint"
  dimensions = {
    ServiceName = var.ably_vpc_service_endpoint_name
  }
  period            = "60"
  statistic         = "Maximum"
  threshold         = "1"
  alarm_description = "This metric indicates whether an Ably region has been disabled by the Ably Incident Response team"
}

resource "aws_route53_health_check" "privatelink_disabled_status" {
  for_each                        = toset(var.regions)
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.privatelink_disabled_status[each.key].alarm_name
  cloudwatch_alarm_region         = each.key
  insufficient_data_health_status = "Healthy"
  invert_healthcheck              = false
  measure_latency                 = false

  tags = {
    "Name" = "ably-privatelink-region-status-${each.key}"
  }
}
