output "security_group_id" {
  value = "${aws_security_group.ose.id}"
}

output "iam_access_key" {
  value = "${aws_iam_access_key.ose.id}"
}

output "iam_secret_key" {
  value = "${aws_iam_access_key.ose.secret}"
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

output "hostname_master" {
  value = "${aws_route53_record.master_root.name}"
}

output "hostname_apps" {
  value = "${aws_route53_record.apps_root.name}"
}
