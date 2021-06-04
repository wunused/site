---
title: "Automating Deployments of this Site"
date: 2021-06-03
---

*Edited 2021-06-03 for brevity.*

This website is generated using Hugo, hosted in Amazon Web Services, and
automatically deployed using a workflow in GitHub Actions anytime I push a
change to the `main` branch of my GitHub repository. This post documents the
steps that I took to configure the hosting and automated deployment of this
site.

The code that I use to create and deploy this site can be found on
[GitHub](https://github.com/wunused/site).

## Overview

My goal is to keep the maintenance of this personal website as simple as
possible. I achieve this by combining a few technologies that enable to me
create, modify, and deploy web content from version-controlled Markdown files.

[Hugo](https://gohugo.io/) is a static site generator that converts Markdown
files to HTML. I use the Hugo theme
[cactus](https://themes.gohugo.io/hugo-theme-cactus/) to give my site a simple
and clean aesthetic design. Hugo documentation[^hugo-config][^cactus-readme]
helps me configure my site so that my web content is generated with the
`$ hugo --minify` command.

[^hugo-config]: https://gohugo.io/getting-started/configuration/#configuration-file

[^cactus-readme]: https://github.com/monkeyWzr/hugo-theme-cactus/blob/master/README.md

I host the Hugo-generated web content in infrastructure provided by Amazon Web
Services. My web content is stored in an AWS S3 bucket, which is configured to
host the content for a static website. Domain name lookups for my domain are
managed by AWS Route 53, and my HTTPS certificates and content delivery are
managed and configured in AWS CloudFront.

To configure my S3 bucket[^s3-config], I ensure that it is configured to host a
static website, I enable logging, and I set the bucket to be publicly
accessible. I also create a second bucket that redirects to the first, to
handle traffic to both `wunused.com` and `www.wunused.com`. Note that S3
hosting only provides support for HTTP traffic. HTTPS support can be added with
AWS CloudFront.

[^s3-config]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html

I configure Route 53 to create a Hosted Zone[^route-53-hosted-zone], and then
for my Namecheap domain settings[^namecheap] to use *custom DNS nameservers* provided by
Route 53. I note that Route 53 now becomes the DNS provider, so other services,
like mail, would need to be configured in Route 53 and not in Namecheap.

[^route-53-hosted-zone]: https://benjamincongdon.me/blog/2017/06/13/How-to-Deploy-a-Secure-Static-Site-to-AWS-with-S3-and-CloudFront/#step-4-configure-route53-to-route-traffic-from-our-custom-domain

[^namecheap]: https://www.namecheap.com/support/knowledgebase/article.aspx/10371/2208/how-do-i-link-my-domain-to-amazon-web-services/

CloudFront allows me to configure HTTPS support[^cloudfront-https] and create SSL/TLS
certificates.[^cloudfront-certificate-creation] I ensure that Route 53 and
CloudFront and Route 53 are properly
integrated.[^cloudfront-route-53-integration]

[^cloudfront-https]: https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-https-requests-s3/

[^cloudfront-certificate-creation]: https://aws.amazon.com/premiumsupport/knowledge-center/install-ssl-cloudfront/

[^cloudfront-route-53-integration]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-cloudfront-distribution.html#routing-to-cloudfront-distribution-config

I use AWS IAM to create a new user with only enough permissions necessary to
deploy my web content to AWS - specifically, to push content to my S3 bucket,
and to invalidate the CloudFront cache.[^iam-config] This helps enforce the
principle of least privilege.

[^iam-config]: https://capgemini.github.io/development/Using-GitHub-Actions-and-Hugo-Deploy-to-Deploy-to-AWS/

My GitHub Actions [workflow](https://github.com/wunused/site/blob/main/.github/workflows/deploy.yml)
builds my web content in one job and deploys the content to my AWS
infrastructure in another. I use GitHub Secrets to keep sensitive information
out of my publicly accessible configuration file for the workflow, and I use
artifacts to pass information between the two jobs. The workflow triggers only
on push actions to `main`.

So far, my site hosting and deployment is entirely within AWS and GitHub
Actions free tiers, with the exception of AWS Route 53 services, which come
with a cost of $0.50 per month, per domain. I also pay annually to register my
domain on Namecheap, on the order of about $15 per year.
