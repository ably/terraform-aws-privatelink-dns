/**
 * # Ably AWS PrivateLink DNS Module Example
 *
 * Provides an example of how to deploy an Interface VPC Endpoint and Ably DNS setup. See repository readme for pre-requisites.
 * You will also need to provide AWS credentials to be able to plan/apply this. Documentation on how to authenticate with AWS when using terraform is here [AWS Provider Auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
 */


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.20"
    }
  }
}


