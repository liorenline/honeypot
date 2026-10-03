variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "my_ip" {
  description = "My IP"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (ARM/Graviton)"
  type        = string
  default     = "t4g.small"
}

variable "root_volume_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 15
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key for the honeypot server"
  type        = string
  default     = "~/.ssh/honeypot.pub"
}