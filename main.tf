/**
 * # Ably Privatelink DNS
 * Use this module to configure custom AWS Route53 DNS Records for using Ably over AWS PrivateLink.
 * **NOTE:** You need an active Ably account and will need to engage with Ably's Partner & SRE teams to make use of this module. It will also require discussions about TLS certificates.
 * 
 * For PrivateLink documentation, see [AWS PrivateLink](https://aws.amazon.com/privatelink)
 * 
 * ## Pre-requisites
 * 
 * Before you can use this module, you will need to go through some setup with your Ably account manager. This includes providing the IDs of the AWS accounts you expect to make PrivateLink connections from, and agreeing which AWS regions and availability zones you will ll be connecting from. Once you have completed that setup, you will then need to create Ably VPC Endpoints. Follow instructions [Here](https://github.com/ably/terraform-aws-privatelink). In addition to the VPC Endpoints, you will also need to create a Route53 Private Hosted zone so that this module can create DNS records for you.
 * The example folder includes a starting example for reference.
 * 
 * ## Infrastructure created by this module
 * 
 * This module will provision the following infrastructure:
 * 
 * - Route53 Apex DNS Record for your chosen subdomain. Type = Alias with Latency Routing policy for the relevant AWS region. E.G. subdomain.example.com (With Latency Record for relevant AWS Region)
 * - Route53 DNS record for regional DNS. Type = CNAME and points your regions VPC endpoint DNS record. E.G. eu-west-1.subdomain.example.com
 * - Route53 DNS record for zonal DNS. Type = CNAME and points at your AWS Region's VPC endpoint for AWS Availability Zone. E.G. eu-west-1a.subdomain.example.com
 * 
 * ## Verifying that your DNS records and VPC Endpoint are responding to requests
 * 
 * Once you have successfully applied the module, you can verify that the DNS Records & VPC endpoint are working correctly by running the following curl command from within your VPC.
 * 
 * ```bash
 * dig +short {Your DNS Record} # This should return DNS record information
 * curl -Iv http://{Your DNS Record}/health. # This will test your Ably VPC Endpoint Connection.
 * ```  
 * You should receive an HTTP 200 status code with the body of the response containing the phrase 'Ably Up'.
 * 
 * Documentation on troubleshooting AWS Interface VPC endpoints can be found here - [Troubleshooting Interface VPC Endpoints](https://aws.amazon.com/premiumsupport/knowledge-center/connect-endpoint-service-vpc/).
 * 
 * ## Usage
 * 
 * ```terraform
 * module "ably_privatelink" {
 *   source                          = "ably/terraform-aws-privatelink"
 *   version                         = "0.1.0"
 *   vpc_id                          = "vpc_id"
 *   ably_vpc_service_endpoint_name  = "vpc_service_endpoint"
 *   subnet_ids                      = ['subnet_id']
 *   vpc_endpoint_sg_name            = "ably-privatelink-vpc-endpoint-sg"
 *   vpc_endpoint_sg_description     = "Ably PrivateLink VPC Endpoint SG"
 *   https_ingress_allowed_ipv4_cidr = ["10.0.0.0/8"]
 *   http_ingress_allowed_ipv4_cidr  = ["10.0.0.0/8"]
 *   https_ingress_allowed_ipv6_cidr = []
 *   http_ingress_allowed_ipv6_cidr  = []
 *   egress_allowed_ipv4_cidr        = ["0.0.0.0/0"]
 *   egress_allowed_ipv6_cidr        = ["::/0"]
 * }
 * 
 * resource "aws_route53_zone" "private" {
 *   name = "example.com"
 *   vpc {
 *     vpc_id = "Your VPC ID"
 *   }
 * }
 * 
 * module "ably_privatelink_dns" {
 *   source                               = "ably/terraform-aws-privatelink-dns"
 *   version                              = "0.1.4"
 *   for_each                             = var.region_config
 *   route53_private_zone_id              = aws_route53_zone.private.id
 *   ably_vpc_endpoint_dns_entry          = module.ably_privatelink[each.key].vpc_endpoint_dns_name
 *   ably_vpc_endpoint_dns_hosted_zone_id = module.ably_privatelink[each.key].vpc_endpoint_dns_hosted_zone_id
 *   dns_global_record                    = "example.com"
 *   regions                              = [each.key]
 *   azs                                  = toset(each.value)
 *   depends_on = [
 *     module.ably_privatelink
 *   ]
 * }
 * ```
 * 
 *  Variables referenced above should be of type map(map(string))
 * Example
 * ```terraform
 * variable "ably_vpc_service_endpoint_name" {
 *   description = "Map containing Ably VPC Endpoint Services"
 *   type        = map(string)
 *   default = {
 *     eu-west-1 = "com.amazonaws.vpce.eu-west-1.vpce-svc-XXXXX"
 *   }
 * }
 * 
 * variable "region_config" {
 *   type        = map(list(string))
 *   description = "Map(list) of regional information use for the privatelink dns module"
 *   default = {
 *     eu-west-1 = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
 *   }
 * }
 * ```
*/


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.20"
    }
  }
}
