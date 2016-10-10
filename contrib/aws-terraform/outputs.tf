output "security_group_id" {
  value = "${aws_security_group.ose.id}"
}

output "iam_access_key" {
  value = "${aws_iam_access_key.ose.id}"
}

output "iam_secret_key" {
  value = "${aws_iam_access_key.ose.secret}"
}
