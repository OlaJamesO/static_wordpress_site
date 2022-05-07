locals {
  aws_region  = "eu-west-2"
  site_name   = "jameso"
  profile     = "iamadmin-prod"
  site_domain = "jameso.tech"
}

data "aws_caller_identity" "current" {}

module "olajames_vpc" {
  source = "./vpc_setup"
}

module "olajames_website" {
  source         = "TechToSpeech/serverless-static-wordpress/aws"
  version        = "0.1.2"
  main_vpc_id    = module.olajames_vpc.main_vpc_id
  subnet_ids     = tolist(module.olajames_vpc.subnet_ids)
  aws_account_id = data.aws_caller_identity.current.account_id

  # site_name will be used to prepend resource names - use no spaces or special characters
  site_name           = local.site_name
  site_domain         = local.site_domain
  wordpress_subdomain = "wordpress"
  hosted_zone_id      = "Z06850212T35C4K8MKBCL"
  s3_region           = local.aws_region
  slack_webhook       = "https://hooks.slack.com/services/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"
  ecs_cpu             = 1024
  ecs_memory          = 2048
  cloudfront_aliases  = ["www.jameso.tech", "jameso.tech"]
  waf_enabled         = false

  # Provides the toggle to launch Wordpress container
  launch = 0

  ## Passing in Provider block to module is essential
  providers = {
    aws.ue1 = aws.ue1
  }
}

# Optional (but highly recommended) helper module for pull/push official Wordpress docker image to ECR

module "docker_pullpush" {
  source         = "TechToSpeech/ecr-mirror/aws"
  version        = "0.0.7"
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = local.aws_region
  docker_source  = "wordpress:php7.4-apache"
  aws_profile    = local.profile
  ecr_repo_name  = module.olajames_website.wordpress_ecr_repository
  ecr_repo_tag   = "base"
  depends_on     = [module.olajames_website]
}


# Optional helper resources to trigger CodeBuild

resource "null_resource" "trigger_build" {
  triggers = {
    codebuild_etag = module.olajames_website.codebuild_package_etag
  }
  provisioner "local-exec" {
    command = "aws codebuild start-build --project-name ${module.olajames_website.codebuild_project_name} --profile ${local.profile} --region ${local.aws_region}"
  }
  depends_on = [
    module.olajames_website, module.docker_pullpush
  ]
}


# Optional helper resources to update nameservers of newly-created Hosted Zone

/*resource "aws_route53_zone" "apex" {
  name = "jameso.tech"
}

resource "null_resource" "update_nameservers" {
  triggers = {
    nameservers = aws_route53_zone.apex.id
  }
  provisioner "local-exec" {
    command = "aws route53domains update-domain-nameservers --region us-east-1 --domain-name ${local.site_domain} --nameservers Name=${aws_route53_zone.apex.name_servers.0} Name=${aws_route53_zone.apex.name_servers.1} Name=${aws_route53_zone.apex.name_servers.2} Name=${aws_route53_zone.apex.name_servers.3} --profile ${local.profile}"
  }
  depends_on = [aws_route53_zone.apex]
}*/
