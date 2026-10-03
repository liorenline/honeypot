data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-resolute-26.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "honeypot" {
  key_name   = "honeypot"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_instance" "honeypot" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.honeypot.id]
  key_name               = aws_key_pair.honeypot.key_name

  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "honeypot"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "honeypot" {
  domain   = "vpc"
  instance = aws_instance.honeypot.id

  tags = {
    Name = "honeypot-eip"
  }

  depends_on = [aws_internet_gateway.main]
}