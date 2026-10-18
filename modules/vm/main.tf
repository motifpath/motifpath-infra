data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

resource "aws_security_group" "this" {
  name        = var.name
  description = "Public HTTP and HTTPS only; no SSH, shell access goes through Session Manager."
  vpc_id      = var.vpc_id

  tags = { Name = var.name }
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = {
    http-ipv4  = { port = 80, cidr_ipv4 = "0.0.0.0/0" }
    https-ipv4 = { port = 443, cidr_ipv4 = "0.0.0.0/0" }
  }

  security_group_id = aws_security_group.this.id
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr_ipv4
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_iam_role" "this" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Session Manager shell access and Run Command, which deploys use.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                     = data.aws_ssm_parameter.ami.value
  instance_type           = var.instance_type
  subnet_id               = var.subnet_id
  vpc_security_group_ids  = [aws_security_group.this.id]
  iam_instance_profile    = aws_iam_instance_profile.this.name
  disable_api_termination = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    compose_version = var.compose_version
    swap_size_mb    = var.swap_size_mb
  })

  metadata_options {
    http_tokens = "required"
    # Containers sit one network hop behind the host; with the default limit
    # of 1 the AWS SDK inside them cannot reach the instance role.
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size_gb
    encrypted   = true
  }

  tags = { Name = var.name }

  lifecycle {
    # A newer AMI or boot script must not silently replace or reboot the VM
    # both environments run on. Roll either out on purpose with
    # `terraform apply -replace=...`.
    ignore_changes = [ami, user_data]
  }
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.this.id

  tags = { Name = var.name }
}
