---
title: "Automating Deployments of this Site"
date: 2021-06-03
---

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
and clean aesthetic design.

I host the Hugo-generated web content in infrastructure provided by Amazon
Web Services. My web content is stored in an
[AWS Simple Storage Service (S3)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
bucket, which is configured to host the content for a static website. Domain
name lookups for my domain are managed by
[AWS Route 53](https://aws.amazon.com/route53/), and my HTTPS certificates and
content delivery are managed and configured in
[AWS CloudFront](https://aws.amazon.com/cloudfront/).

I use [GitHub Actions](https://docs.github.com/en/actions) to automate the
content generation and deployment to my AWS infrastructure. This allows me to
make site updates by editing Markdown files and pushing them to GitHub,
achieving my goal of simple site maintenance.

So far, my site hosting and deployment is entirely within AWS and GitHub
Actions free tiers, with the exception of AWS Route 53 services, which come
with a cost of $0.50 per month, per domain. I also pay annually to register my
domain on Namecheap, on the order of about $15 per year.

## Content Creation with Hugo

Hugo allows me to create website content from simple Markdown files. It is easy
to get started by
[installing Hugo](https://gohugo.io/getting-started/installing/)
and selecting a
[theme](https://themes.gohugo.io/). Most themes have
[example code](https://github.com/monkeyWzr/hugo-theme-cactus/tree/master/exampleSite)
to show how to structure a repository to use the theme. Once selected, I add it
as a submodule in a directory named `themes`.

The [Hugo documentation](https://gohugo.io/getting-started/configuration/#configuration-file)
is helpful for learning how to create a `config.toml` file that specifies how
Hugo should generate your site. Some values in the `config.toml` file are
specific to the theme that I choose, so I additionally reference the
[cactus theme's documentation](https://github.com/monkeyWzr/hugo-theme-cactus/blob/master/README.md).

When I'm ready to generate my website, I run `$ hugo --minify` in the root
directory of the repository. If everything is configured correctly, this
creates a subdirectory named `public` that contains all of the generated HTML,
JavaScript, and other web content that can be hosted with a web server. To
deploy my site, I place the contents of the `public` directory in a location
where my web server can host them.[^hugo-deployment]

[^hugo-deployment]: Hugo also provides the `hugo server` and `hugo deploy`
commands, but I do not use them in my deployment. `server` will host a local
server that serves the generated content, which is useful for local testing
before pushing to the live site. `deploy` will push your content to configured
cloud hosting infrastructure, like AWS. I choose not to use this command, and
instead use the AWS CLI to achieve the same outcome.

## Content Hosting in an AWS S3 Bucket

My site is hosted in Amazon Web Services infrastructure.

To start, I create an AWS account and use it to create two S3 buckets - one
primary bucket named `wunused.com`, and one for subdomain redirection, named
`www.wunused.com`, which will redirect requests to the primary bucket. This
will allow users to browse to either `wunused.com` or `www.wunused.com` once
I've also configured my domain name resolution.

I ensure that the primary bucket is configured to host a static website, I
enable logging, and I set the bucket to be publicly accessible with read
permissions.

I can now move content into the primary AWS bucket by uploading content from
the AWS web GUI, or through the AWS CLI with the `aws s3 sync` command.

Note that S3 hosting only provides support for unencrypted HTTP traffic. HTTPS
support can be added with AWS CloudFront configuration, which I will describe
[shortly](#https-and-cdn-services-with-aws-cloudfront).

The steps above are well-documented in
[AWS guides](https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html).

## Domain Name Resolution with AWS Route 53

Once an S3 bucket hosts my website content, I need to be able to route
traffic to it by using my domain name, `wunused.com`. My domain name is
purchased and registered with Namecheap, and I use AWS Route 53 to ensure that
traffic is routed to my S3 bucket.

To do so, I use Route 53
[to create a Hosted Zone](https://benjamincongdon.me/blog/2017/06/13/How-to-Deploy-a-Secure-Static-Site-to-AWS-with-S3-and-CloudFront/#step-4-configure-route53-to-route-traffic-from-our-custom-domain). I
then need to configure my Namecheap domain settings to use
*Custom DNS Nameservers*, and enter the custom servers that Route 53 provides
for the Hosted Zone. Namecheap provides
[simple documentation](https://www.namecheap.com/support/knowledgebase/article.aspx/10371/2208/how-do-i-link-my-domain-to-amazon-web-services/)
for this.

Note that AWS Route 53 now becomes the DNS provider, so any other services,
like mail, need to be configured in AWS Route 53 and not in the original
registrar.

## HTTPS and CDN Services with AWS CloudFront

Simple static hosting in S3 does not provide support for HTTPS traffic. To add
HTTPS support, certificates for my site need to be configured in AWS
CloudFront, which is Amazon's content delivery network (CDN) service.

I reference the AWS documentation for [configuring CloudFront with HTTPS](https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-https-requests-s3/)
and [creating SSL/TLS certificates](https://aws.amazon.com/premiumsupport/knowledge-center/install-ssl-cloudfront/).
I also ensure that
[Route 53 and CloudFront integration](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-cloudfront-distribution.html#routing-to-cloudfront-distribution-config)
is configured correctly.

Once CloudFront is configured, in order to make changes to the site, I need to
invalidate the cached files in the CloudFront CDN after making changes to the
files in the S3 bucket. This can be done through the AWS CLI with the
`aws cloudfront create-invalidation` command.

## Principle of Least Privilege with AWS Identity & Access Management (IAM)

Thus far, I configure AWS infrastructure through the management console
with an administrator account. However, when I automate site deployments and
delegate permissions to the automated components (like GitHub Actions), I
prefer to grant permissions using the principle of least privilege. To do so,
I use [AWS Identity & Access Management (IAM)](https://aws.amazon.com/iam/)
to create a new user with only the permissions necessary for uploading files to
S3 and invalidating the CloudFront cache. This user's credentials are what I
will provide to GitHub to use in the workflow.

The permission policy for the new user that I set in AWS IAM is:[^IAM-policy]

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GitHubActionsPolicy",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutBucketPolicy",
                "s3:ListBucket",
                "cloudfront:CreateInvalidation",
                "s3:GetBucketPolicy"
            ],
            "Resource": [
                "arn:aws:cloudfront::ACCOUNT_NO:distribution/CLOUDFRONT_DIST_ID",
                "arn:aws:s3:::S3_BUCKET_NAME",
                "arn:aws:s3:::S3_BUCKET_NAME/*"
            ]
        }
    ]
}
```

Where `ACCOUNT_NO`, `CLOUDFRONT_DIST_ID`, and `S3_BUCKET_NAME` should be
specific to my account. This constrains the new user from only applying the
permitted actions to the resources specific to the S3 bucket and CloudFront
distribution for this site.

[^IAM-policy]: I use
[this reference](https://capgemini.github.io/development/Using-GitHub-Actions-and-Hugo-Deploy-to-Deploy-to-AWS/)
for creating the IAM permission policy.

## Automated Deployments with GitHub Actions

Once the AWS infrastructure is configured and deployed, and the code is hosted
on GitHub, I am ready to automate the deployment of the site with a GitHub
Actions workflow.

This is configured in the
[`.github/worflows/deploy.yml`](https://github.com/wunused/site/blob/main/.github/workflows/deploy.yml)
file that defines the workflow. I configure it to execute on each push to the
`main` branch, and I create two jobs: one named `build` that generates the web
content with Hugo, and one named `deploy` that pushes the contents to AWS. I
ensure that any of my sensitive credentials are **NOT** listed explicitly in
the deploy file, and instead saved as GitHub Secrets so they cannot be accessed
publicly. I use artifacts to pass persistent files between the two jobs, and I
configure the jobs to run one after another, rather than in parallel (parallel
execution is the default behavior). This allows the `build` job to execute and
finish, in which the web content is created as artifacts, and then the `deploy`
job executes and pushes the content artifacts to the site.

Once the `deploy.yml` file is pushed to GitHub and my secrets are registered,
all I need to do to deploy changes to my website is new Markdown to the `main`
branch.

## Conclusion

This post describes the steps to configure the automated deployment of this
personal website using Hugo, AWS, and GitHub Actions. This has been a good
first experience for me to learn the features of AWS and GitHub for automated
deployments in cloud infrastructure.
