variable "keypair" {
  default = "christian.simon"
}

variable "master_instance_type" {
  default = "m4.large"
}

variable "node_instance_type" {
  default = "m4.large"
}

variable "aws_availability_zone" {
  default = "eu-west-1b"
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

variable "master_ip" {
  default = "52.212.28.113"
}

output "node_infra_ips" {
  value = ["${aws_instance.ose-node-infra.*.public_ip}"]
}

output "nodes_infra_hosts" {
  value = ["${aws_instance.ose-node-infra.*.public_dns}"]
}

output "node_compute_ips" {
  value = ["${aws_instance.ose-node-compute.*.public_ip}"]
}

output "nodes_compute_hosts" {
  value = ["${aws_instance.ose-node-compute.*.public_dns}"]
}

output "master_ip" {
  value = ["${aws_instance.ose-master.*.public_ip}"]
}

output "master_dns" {
  value = ["${aws_instance.ose-master.*.public_dns}"]
}

output "subnet_id" {
  value = "${aws_subnet.main.id}"
}

output "operating_system" {
  value = "${var.operating_system}"
}
