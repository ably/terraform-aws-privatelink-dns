# [Ably](https://www.ably.io)

\_[Ably](https://ably.com) is the platform that powers synchronized digital experiences in realtime. Whether attending an event in a virtual venue, receiving realtime financial information, or monitoring live car performance data – consumers simply expect realtime digital experiences as standard. Ably provides a suite of APIs to build, extend, and deliver powerful digital experiences in realtime for more than 250 million devices across 80 countries each month. Organizations like Bloomberg, HubSpot, Verizon, and Hopin depend on Ably’s platform to offload the growing complexity of business-critical realtime data synchronization at global scale. For more information, see the [Ably documentation](https://ably.com/documentation).\_

# Ably Privatelink DNS
Use this module to configure custom AWS Route53 DNS Records for using Ably over AWS PrivateLink.
**NOTE:** You need an active Ably account and will need to engage with Ably's Partner & SRE teams to make use of this module. It will also require discussions about TLS certificates.

For PrivateLink documentation, see [AWS PrivateLink](https://aws.amazon.com/privatelink)

## Pre-requisites

Before you can use this module, you will need to go through some setup with your Ably account manager. This includes providing the IDs of the AWS accounts you expect to make PrivateLink connections from, and agreeing which AWS regions and availability zones you will ll be connecting from. Once you have completed that setup, you will then need to create Ably VPC Endpoints. Follow instructions [Here](https://github.com/ably/terraform-aws-privatelink). In addition to the VPC Endpoints, you will also need to create a Route53 Private Hosted zone so that this module can create DNS records for you.
The example folder includes a starting example for reference.

## Infrastructure created by this module

This module will provision the following infrastructure:

- Route53 Apex DNS Record for your chosen subdomain. Type = Alias with Latency Routing policy for the relevant AWS region. E.G. subdomain.example.com (With Latency Record for relevant AWS Region)
- Route53 DNS record for regional DNS. Type = CNAME and points your regions VPC endpoint DNS record. E.G. eu-west-1.subdomain.example.com
- Route53 DNS record for zonal DNS. Type = CNAME and points at your AWS Region's VPC endpoint for AWS Availability Zone. E.G. eu-west-1a.subdomain.example.com

## Verifying that your DNS records and VPC Endpoint are responding to requests

Once you have successfully applied the module, you can verify that the DNS Records & VPC endpoint are working correctly by running the following curl command from within your VPC.

```bash
dig +short {Your DNS Record} # This should return DNS record information
curl -Iv http://{Your DNS Record}/health. # This will test your Ably VPC Endpoint Connection.
```
You should receive an HTTP 200 status code with the body of the response containing the phrase 'Ably Up'.

Documentation on troubleshooting AWS Interface VPC endpoints can be found here - [Troubleshooting Interface VPC Endpoints](https://aws.amazon.com/premiumsupport/knowledge-center/connect-endpoint-service-vpc/).

## Usage

```terraform
module "ably_privatelink" {
  source                          = "ably/terraform-aws-privatelink"
  version                         = "0.1.0"
  vpc_id                          = "vpc_id"
  ably_vpc_service_endpoint_name  = "vpc_service_endpoint"
  subnet_ids                      = ['subnet_id']
  vpc_endpoint_sg_name            = "ably-privatelink-vpc-endpoint-sg"
  vpc_endpoint_sg_description     = "Ably PrivateLink VPC Endpoint SG"
  https_ingress_allowed_ipv4_cidr = ["10.0.0.0/8"]
  http_ingress_allowed_ipv4_cidr  = ["10.0.0.0/8"]
  https_ingress_allowed_ipv6_cidr = []
  http_ingress_allowed_ipv6_cidr  = []
  egress_allowed_ipv4_cidr        = ["0.0.0.0/0"]
  egress_allowed_ipv6_cidr        = ["::/0"]
}

resource "aws_route53_zone" "private" {
  name = "example.com"
  vpc {
    vpc_id = "Your VPC ID"
  }
}

module "ably_privatelink_dns" {
  source                               = "ably/terraform-aws-privatelink-dns"
  version                              = "0.1.4"
  for_each                             = var.region_config
  route53_private_zone_id              = aws_route53_zone.private.id
  ably_vpc_endpoint_dns_entry          = module.ably_privatelink[each.key].vpc_endpoint_dns_name
  ably_vpc_endpoint_dns_hosted_zone_id = module.ably_privatelink[each.key].vpc_endpoint_dns_hosted_zone_id
  dns_global_record                    = "example.com"
  regions                              = [each.key]
  azs                                  = toset(each.value)
  depends_on = [
    module.ably_privatelink
  ]
}
```

 Variables referenced above should be of type map(map(string))
Example
```terraform
variable "ably_vpc_service_endpoint_name" {
  description = "Map containing Ably VPC Endpoint Services"
  type        = map(string)
  default = {
    eu-west-1 = "com.amazonaws.vpce.eu-west-1.vpce-svc-XXXXX"
  }
}

variable "region_config" {
  type        = map(list(string))
  description = "Map(list) of regional information use for the privatelink dns module"
  default = {
    eu-west-1 = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  }
}
```

## Support, feedback and troubleshooting

Please visit http://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

You can also view the community reported Github issues.

## Contributing

For guidance on how to contribute to this project, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.privatelink_disabled_status](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_route53_health_check.privatelink_disabled_status](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_health_check) | resource |
| [aws_route53_record.ably-global](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.ably-regional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.ably-zonal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ably_vpc_endpoint_dns_entry"></a> [ably\_vpc\_endpoint\_dns\_entry](#input\_ably\_vpc\_endpoint\_dns\_entry) | The top level DNS entry exposed by your VPC Endpoint (Non-AZ version) | `string` | n/a | yes |
| <a name="input_ably_vpc_endpoint_dns_hosted_zone_id"></a> [ably\_vpc\_endpoint\_dns\_hosted\_zone\_id](#input\_ably\_vpc\_endpoint\_dns\_hosted\_zone\_id) | Hosted Zone ID for your VPC Endpoint | `string` | n/a | yes |
| <a name="input_ably_vpc_service_endpoint_name"></a> [ably\_vpc\_service\_endpoint\_name](#input\_ably\_vpc\_service\_endpoint\_name) | VPC Service endpoint to use for Cloudwatch Alarms. This will be provided by Ably. | `string` | n/a | yes |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of AWS Availability Zones that you have created VPC endpoints in. Used to create zonal DNS entries for PrivateLink Connections. e.g. eu-west-1a.example.com and eu-west-1b.example.com | `list(string)` | n/a | yes |
| <a name="input_dns_global_record"></a> [dns\_global\_record](#input\_dns\_global\_record) | The global DNS CNAME record that you wish to use in a Private DNS Hosted Zone. This should be discussed with Ably. | `string` | n/a | yes |
| <a name="input_dns_global_record_ttl"></a> [dns\_global\_record\_ttl](#input\_dns\_global\_record\_ttl) | TTL Value in seconds for the global DNS CNAME record that you wish to use in a Private DNS Hosted Zone. | `string` | `60` | no |
| <a name="input_dns_regional_record_ttl"></a> [dns\_regional\_record\_ttl](#input\_dns\_regional\_record\_ttl) | TTL Value in seconds for the regional DNS CNAME record that you wish to use in a Private DNS Hosted Zone. | `string` | `60` | no |
| <a name="input_dns_zonal_record_ttl"></a> [dns\_zonal\_record\_ttl](#input\_dns\_zonal\_record\_ttl) | TTL Value in seconds for the zonal DNS CNAME record that you wish to use in a Private DNS Hosted Zone. | `string` | `60` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | AWS regions to use with PrivateLink. Used to create a regional DNS entry for PrivateLink Connections. E.G. eu-west-1.example.com | `list(any)` | n/a | yes |
| <a name="input_route53_private_zone_id"></a> [route53\_private\_zone\_id](#input\_route53\_private\_zone\_id) | ID of Route53 Private Hosted Zone to use | `string` | n/a | yes |

## Outputs

No outputs.
