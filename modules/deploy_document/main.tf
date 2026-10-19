# The only command a deploy role may send to the VM. It takes nothing but an
# image tag, checks that commit is on one of this environment's release
# branches, and runs the deploy script from that commit, fetched by the VM
# itself. A caller therefore cannot run code of its choosing on the host
# shared with the other environment: only code already merged to those
# branches runs.
resource "aws_ssm_document" "this" {
  name            = var.name
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Deploy ${var.repository} to ${var.environment} at a commit on ${join(" or ", var.allowed_branches)}."
    parameters = {
      imageTag = {
        type           = "String"
        description    = "Full commit SHA whose images and deploy files are deployed."
        allowedPattern = "^[0-9a-f]{40}$"
      }
    }
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "deploy"
      inputs = {
        timeoutSeconds = tostring(var.timeout_seconds)
        runCommand = split("\n", templatefile("${path.module}/deploy.sh.tftpl", {
          environment      = var.environment
          repository       = var.repository
          allowed_branches = join(" ", var.allowed_branches)
        }))
      }
    }]
  })
}
