resource "aws_route53_record" "master1" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.dns_zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.ose-master.*.public_ip}"]
}

resource "aws_route53_record" "master2" {
  zone_id = "${var.dns_zone_id}"
  name    = "master.${var.dns_zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.ose-master.*.public_ip}"]
}

resource "aws_route53_record" "wildcard" {
  zone_id = "${var.dns_zone_id}"
  name    = "*.${var.dns_zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.ose-node-infra.*.public_ip}"]
}
