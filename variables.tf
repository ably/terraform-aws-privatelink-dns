variable "route53_private_zone_id" {
  description = "ID of Route53 Private Hosted Zone to use"
  type        = string
}

variable "ably_vpc_endpoint_dns_entry" {
  description = "The top level DNS entry exposed by your VPC Endpoint (Non-AZ version)"
  type        = string
}

variable "ably_vpc_endpoint_dns_hosted_zone_id" {
  description = "Hosted Zone ID for your VPC Endpoint"
  type        = string
}

variable "dns_global_record" {
  description = "The global DNS CNAME record that you wish to use in a Private DNS Hosted Zone. This should be discussed with Ably."
  type        = string
}

variable "dns_global_record_ttl" {
  description = "TTL Value in seconds for the global DNS CNAME record that you wish to use in a Private DNS Hosted Zone."
  type        = string
  default     = 60
}

variable "regions" {
  type        = list(any)
  description = "AWS regions to use with PrivateLink. Used to create a regional DNS entry for PrivateLink Connections. E.G. eu-west-1.example.com"
}

variable "azs" {
  type        = list(string)
  description = "A list of AWS Availability Zones that you have created VPC endpoints in. Used to create zonal DNS entries for PrivateLink Connections. e.g. eu-west-1a.example.com and eu-west-1b.example.com"
}

variable "dns_regional_record_ttl" {
  description = "TTL Value in seconds for the regional DNS CNAME record that you wish to use in a Private DNS Hosted Zone."
  type        = string
  default     = 60
}

variable "dns_zonal_record_ttl" {
  description = "TTL Value in seconds for the zonal DNS CNAME record that you wish to use in a Private DNS Hosted Zone."
  type        = string
  default     = 60
}

variable "ably_vpc_service_endpoint_name" {
  type        = string
  description = "VPC Service endpoint to use for Cloudwatch Alarms. This will be provided by Ably."
}
