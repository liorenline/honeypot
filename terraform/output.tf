output "public_ip" {
  description = "Honeypot public IP"
  value       = aws_eip.honeypot.public_ip
}

output "instance_id" {
  value = aws_instance.honeypot.id
}

output "ssh_command" {
  description = "Real SSH (after Ansible hardening)"
  value       = "ssh -i ~/.ssh/honeypot -p 22022 ubuntu@${aws_eip.honeypot.public_ip}"
}

output "grafana_tunnel" {
  description = "Open Grafana at http://localhost:3000"
  value       = "ssh -i ~/.ssh/honeypot -p 22022 -N -L 3000:localhost:3000 ubuntu@${aws_eip.honeypot.public_ip}"
}