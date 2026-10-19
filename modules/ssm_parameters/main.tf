resource "aws_ssm_parameter" "string" {
  for_each = var.string_parameters

  name  = "${var.path}/${each.key}"
  type  = "String"
  value = each.value
}

resource "aws_ssm_parameter" "secure" {
  for_each = nonsensitive(toset(keys(var.secure_parameters)))

  name  = "${var.path}/${each.key}"
  type  = "SecureString"
  value = var.secure_parameters[each.key]
}

# Secrets Terraform never sees. Created with a placeholder that makes a
# service fail loudly, then set by hand; Terraform ignores the real value.
resource "aws_ssm_parameter" "manual" {
  for_each = var.manual_parameters

  name        = "${var.path}/${each.key}"
  type        = "SecureString"
  value       = "SET_ME"
  description = "Set by hand: aws ssm put-parameter --overwrite --type SecureString --name ${var.path}/${each.key} --value ..."

  lifecycle {
    ignore_changes = [value]
  }
}
