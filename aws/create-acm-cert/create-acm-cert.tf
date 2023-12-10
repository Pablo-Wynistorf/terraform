provider "aws" {
  region = var.var-region
}
variable "var-region" {
  description = "In what region do you want the infrastructure?"
}


resource "aws_acm_certificate" "domain_request_1" {
  domain_name       = "*.onedns.ch"
  validation_method = "EMAIL"
}

resource "aws_acm_certificate" "domain_request_2" {
  domain_name       = "onedns.ch"
  validation_method = "EMAIL"
}

resource "aws_acm_certificate" "domain_request_3" {
  domain_name       = "*.bla.ch"
  validation_method = "DNS"
}

resource "aws_acm_certificate" "domain_request_4" {
  domain_name       = "bla.ch"
  validation_method = "DNS"
}

#output the dns validation records (in this case for request 4)
output "acm_certificate_validation_dns_records_name" {
  value = aws_acm_certificate.domain_request_4.domain_validation_options[*].resource_record_name
}
output "acm_certificate_validation_dns_records_value" {
  value = aws_acm_certificate.domain_request_4.domain_validation_options[*].resource_record_value
}