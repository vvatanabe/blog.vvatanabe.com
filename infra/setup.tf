variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret access key"
}

variable "region" {
  description = "AWS region to host your network"
}

variable "root_domain" {
  description = "Your root domain name"
}

variable "sub_domain" {
  description = "Your sub domain prefix"
}

variable "domain" {
  description = "Your domain"
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.domain}"
  region = "${var.region}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadForGetBucketObjects",
    "Effect": "Allow",
    "Principal": { "AWS": "*" },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${var.domain}/*"
  }]
}
EOF
  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

data "aws_acm_certificate" "acm" {
  domain = "${var.domain}"
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  comment = "${var.domain}"
  default_root_object = "index.html"
  price_class = "PriceClass_200"
  retain_on_delete = true
  aliases = ["${var.domain}"]
  origin {
    domain_name = "${aws_s3_bucket.site.website_endpoint}"
    origin_id = "${var.domain}"
    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.site.id}"
    compress = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = "${data.aws_acm_certificate.acm.arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

resource "aws_route53_zone" "primary" {
  name = "${var.root_domain}"
}

resource "aws_route53_record" "dns" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "${var.sub_domain}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_cloudfront_distribution.cdn.domain_name}"]
}

