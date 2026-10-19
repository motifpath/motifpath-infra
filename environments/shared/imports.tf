# These mail records were first created by hand in the hosted zone; the
# import blocks adopt them into state instead of creating duplicates. They
# are no-ops once the records are managed, and can be removed after the
# first apply. The apex TXT and MX and the autodiscover SRV are not here:
# they were never created under their right names, so Terraform creates
# them.
locals {
  mail_record_ids = {
    webmail = "email.${var.domain_name}_CNAME"
    dkim1   = "secureserver1._domainkey.${var.domain_name}_CNAME"
    dkim2   = "secureserver2._domainkey.${var.domain_name}_CNAME"
  }
}

import {
  for_each = local.mail_record_ids

  to = module.mail_records.aws_route53_record.this[each.key]
  id = "${module.dns_zone.zone_id}_${each.value}"
}
