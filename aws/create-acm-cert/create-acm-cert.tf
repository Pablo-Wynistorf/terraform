provider "aws" {
  region = var.var-region
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

variable "var-hostname" {
  description = "Enter the hostname you want to create a certificate for"
}

variable "var-method" {
  description = "Enter the validation method. (EMAIL or DNS)"
}

resource "aws_acm_certificate" "domain_request" {
  domain_name       = var.var-hostname
  validation_method = var.var-method
}

#output the dns validation records (in this case for request 4)
output "acm_certificate_validation_dns_records_name" {
  value = aws_acm_certificate.domain_request.domain_validation_options[*].resource_record_name
}
output "acm_certificate_validation_dns_records_value" {
  value = aws_acm_certificate.domain_request.domain_validation_options[*].resource_record_value
}

data "template_file" "render-var-file" {
  template = <<-EOT
var-region            = "${var.var-region}"
var-hostname          = "${var.var-hostname}"
var-method            = "${var.var-method}"
  EOT
}

resource "local_file" "create-var-file" {
  content  = data.template_file.render-var-file.rendered
  filename = "terraform.tfvars"
}