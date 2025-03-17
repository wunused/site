---
title: "Automating Deployments of this Site"
date: 2021-06-03
draft: false
summary: An overview of the steps I took to deploy this site.
---

* *Edited 2022-08-31*
* *Edited 2021-06-03*

## Overview

This website is generated using Hugo, hosted in Amazon Web Services, and
automatically deployed every time I push a change to the `main` branch of the
GitHub repository. My goal was to keep the maintenance of this site simple.
This post describes how I achieved that goal by configuring the site's hosting
and automated deployments.

The code that I use to create and deploy this site is hosted on
[GitHub](https://github.com/wunused/site).

## Generating Content

[Hugo](https://gohugo.io/) is a static site generator that converts Markdown
files to HTML. I used the Hugo theme
[cactus](https://themes.gohugo.io/hugo-theme-cactus/) to give my site a simple
and clean aesthetic. I can generate the HTML web content from Markdown
using the `$hugo --minify` command[^hugo-config][^cactus-readme].

[^hugo-config]: https://gohugo.io/getting-started/configuration/#configuration-file

[^cactus-readme]: https://github.com/monkeyWzr/hugo-theme-cactus/blob/master/README.md

## Configuring Infrastructure

I hosted the Hugo-generated web content in Amazon Web Services infrastructure.
Specifically, AWS S3 stores my web content, AWS Route 53 manages my domain name
lookups, and AWS CloudFront manages HTTPS certificates and content delivery.

To set up my S3 bucket[^s3-config], I configured it to host a static website, I
enabled logging, and I made the bucket publicly accessible. I also created a
second bucket that redirects to the first, to handle traffic to both
`wunused.com` and `www.wunused.com`. Note that S3 hosting only provides support
for HTTP traffic --- I added HTTPS support with AWS CloudFront.

[^s3-config]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html

For DNS resolution, I configured Route 53 to create a Hosted
Zone[^route-53-hosted-zone], and for my Namecheap domain settings[^namecheap]
to use the *custom DNS nameservers* provided by Route 53 (since my domain name
was purchased using Namecheap). This caused Route 53 to become the DNS
provider for my domain, so I also needed to configure other services that use
the domain, like mail, in Route 53 rather than in Namecheap.

[^route-53-hosted-zone]: https://benjamincongdon.me/blog/2017/06/13/How-to-Deploy-a-Secure-Static-Site-to-AWS-with-S3-and-CloudFront/#step-4-configure-route53-to-route-traffic-from-our-custom-domain

[^namecheap]: https://www.namecheap.com/support/knowledgebase/article.aspx/10371/2208/how-do-i-link-my-domain-to-amazon-web-services/

To configure secure connections to my site with HTTPS, I created and configured
SSL/TLS certificates in
CloudFront[^cloudfront-https][^cloudfront-certificate-creation][^cloudfront-route-53-integration].

[^cloudfront-https]: https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-https-requests-s3/

[^cloudfront-certificate-creation]: https://aws.amazon.com/premiumsupport/knowledge-center/install-ssl-cloudfront/

[^cloudfront-route-53-integration]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-cloudfront-distribution.html#routing-to-cloudfront-distribution-config

For permissions management, I used AWS IAM to create a new user with only
enough permissions necessary to deploy my web content to AWS --- specifically,
to push content to my S3 bucket, and to invalidate the CloudFront
cache[^iam-config]. This ensures that if my AWS secret tokens are ever
compromised, the actions that they allow are only the ones necessary for
deploying the site, and nothing more.

[^iam-config]: https://capgemini.github.io/development/Using-GitHub-Actions-and-Hugo-Deploy-to-Deploy-to-AWS/

## Automating Deployments

To automatically deploy my content into my AWS infrastructure, I created a
GitHub Actions
[workflow](https://github.com/wunused/site/blob/main/.github/workflows/deploy.yml)
to build my web content in one job and to deploy the content to my AWS
infrastructure in another. I used GitHub Secrets to keep my sensitive AWS
secret tokens out of my publicly accessible configuration file, and I used
artifacts to pass information between the two jobs. The workflow triggers only
on push actions to `main`.

## Cost

So far, the cost of hosting and deploying my site is entirely within AWS and
GitHub Actions free tiers, except for a $0.50 monthly cost for using AWS Route
53 services. I also pay annually to register my domain on Namecheap, on the
order of about $15 per year.
