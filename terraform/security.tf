resource "aws_security_group" "honeypot" {
  name        = "honeypot-sg"
  description = "Honeypot server: trap ports open, real SSH restricted"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "honeypot-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "trap_ssh" {
  security_group_id = aws_security_group.honeypot.id
  description       = "Trap: bots hit SSH port, redirected to Cowrie"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "trap_direct" {
  security_group_id = aws_security_group.honeypot.id
  description       = "Trap: Cowrie port for direct scans"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2222
  to_port           = 2222
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "admin_ssh" {
  security_group_id = aws_security_group.honeypot.id
  description       = "Admin: real SSH, only from my IP"
  cidr_ipv4         = var.my_ip
  from_port         = 22022
  to_port           = 22022
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "out_http" {
  security_group_id = aws_security_group.honeypot.id
  description       = "Egress: HTTP for apt and package downloads"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "out_https" {
  security_group_id = aws_security_group.honeypot.id
  description       = "Egress: HTTPS for apt, Docker Hub, GeoIP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}