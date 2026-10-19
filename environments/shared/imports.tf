# These mail records were first created by hand in the hosted zone; the
# import blocks adopt them into state instead of creating duplicates. They
# are no-ops once the records are managed, and can be removed after the
# first apply.
locals {
  mail_record_ids = {
    apex_txt     = "${var.domain_name}_TXT"
    mx           = "${var.domain_name}_MX"
    webmail      = "email.${var.domain_name}_CNAME"
    dkim1        = "secureserver1._domainkey.${var.domain_name}_CNAME"
    dkim2        = "secureserver2._domainkey.${var.domain_name}_CNAME"
    autodiscover = "_autodiscover._tcp.${var.domain_name}_SRV"
  }
}

import {
  for_each = local.mail_record_ids

  to = module.mail_records.aws_route53_record.this[each.key]
  id = "${module.dns_zone.zone_id}_${each.value}"
}
