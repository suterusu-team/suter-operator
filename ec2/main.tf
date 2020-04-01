terraform {
  required_version = ">= 0.12, < 0.13"
}

variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "aws region where ec2 instance will be created"
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "number of instances to be created"
}

variable "instance_tag_prefix" {
  type        = string
  default     = "suterusu-node"
  description = "tag of the ec2 instance to be created"
}

variable "instance_names" {
  type        = list
  default     =   ["alice", "bob", "charlie", "dave", "eve", "ferdie"]
  description = "names of the ec2 instances to be created"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "type of the ec2 instance to be created"
}

variable "public_key" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "path to the ssh public key with which you can access new created ec2 instance"
}

variable "private_key" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "path to the ssh private key for remote-exec"
}

variable "public_key_name" {
  type        = string
  default     = "suterusu nodes creator's key"
  description = "name of the key to be added to aws ec2"
}

variable "security_group_name" {
  type        = string
  default     = "suterusu_node"
  description = "name of the security group to be added to ec2 instance"
}

provider "aws" {
  region = var.aws_region
  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

resource "aws_key_pair" "suterusu_node" {
  key_name   = var.public_key_name
  public_key = file(pathexpand(var.public_key))
}

# Obtain the ami of ubuntu 19.10
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-eoan-19.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "suterusu_node" {
  count           = var.instance_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.suterusu_node.name]
  key_name        = aws_key_pair.suterusu_node.key_name
  tags = {
    Name = "${var.instance_tag_prefix}-${count.index < length(var.instance_names) ?
    var.instance_names[count.index] : tostring(count.index + 1)}"
  }

  provisioner "remote-exec" {
    on_failure = continue
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(pathexpand(var.private_key))
      host        = self.public_ip
    }
    inline = [
      "hostname=${var.instance_tag_prefix}-${count.index < length(var.instance_names) ? var.instance_names[count.index] : tostring(count.index + 1)}",
      "additional_arguments=${count.index < length(var.instance_names) ? var.instance_names[count.index] : ""}",
      "echo 127.0.0.1 $hostname | sudo tee -a /etc/hosts",
      "sudo hostnamectl set-hostname $hostname",
      "sudo apt update", # Don't know why one update does not work.
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo groupadd docker",
      "sudo usermod -aG docker ubuntu",
      "mkdir -p /home/ubuntu/.suter/node",
      "mkdir -p /home/ubuntu/.suter/data",
    ]
  }

  provisioner "file" {
    on_failure = continue
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(pathexpand(var.private_key))
      host        = self.public_ip
    }
    source      = "${path.module}/../caddy/"
    destination = "/home/ubuntu/.suter/node/"
  }
}

resource "aws_security_group" "suterusu_node" {
  name = var.security_group_name
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_https_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_alter_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.alter_http_port
  to_port     = local.alter_http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_alter_http_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.alter_http_port
  to_port     = local.alter_http_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_mdns_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.mdns_port
  to_port     = local.mdns_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_mdns_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.mdns_port
  to_port     = local.mdns_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_libp2p_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.libp2p_port
  to_port     = local.libp2p_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_libp2p_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.suterusu_node.id

  from_port   = local.libp2p_port
  to_port     = local.libp2p_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

locals {
  any_port        = 0
  ssh_port        = 22
  http_port       = 80
  alter_http_port = 8080
  https_port      = 443
  libp2p_port     = 30333
  mdns_port       = 5353
  any_protocol    = "-1"
  tcp_protocol    = "tcp"
  udp_protocol    = "udp"
  all_ips         = ["0.0.0.0/0"]
}

output "instance_ip" {
  value = aws_instance.suterusu_node.*.public_ip
}

output "instance_dns" {
  value = aws_instance.suterusu_node.*.public_dns
}

output "instance_tags" {
  value = aws_instance.suterusu_node.*.tags
}
