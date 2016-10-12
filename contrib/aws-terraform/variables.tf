variable "keypair" {
  default = "christian.simon"
}

variable "master_instance_type" {
  default = "m4.large"
}

variable "node_instance_type" {
  default = "m4.large"
}

variable "aws_availability_zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "ebs_root_block_size" {
  default = "50"
}

variable "operating_system" {
  default = "centos7"
}

variable "aws_ami" {
  type = "map"

  default = {
    rhel7-eu-west-1   = "ami-8b8c57f8" #RHEL7.2
    centos7-eu-west-1 = "ami-7abd0209"
  }
}

variable "ssh_user" {
  type = "map"

  default = {
    rhel7   = "ec2-user"
    centos7 = "centos"
  }
}

variable "num_master" {
  default = "1"
}

variable "num_node_compute" {
  default = "2"
}

variable "num_node_infra" {
  default = "1"
}

provider "aws" {
  region = "${var.aws_region}"
}

variable "internal_tcp_ports" {
  default = [22, 80, 443, 8443, 10250]
}

variable "public_tcp_ports" {
  default = [22, 80, 443, 8443]
}

variable "udp_ports" {
  default = [4789]
}

variable "cluster_id" {
  default = "jetstack"
}

variable "cluster_env" {
  default = "dev"
}

variable "cluster_creator" {
  default = "christian.simon"
}

variable "dns_zone_id" {
  default = "Z34VZCMBM4IUIP"
}

variable "dns_zone_name" {
  default = "openshift.jetstack.net"
}
