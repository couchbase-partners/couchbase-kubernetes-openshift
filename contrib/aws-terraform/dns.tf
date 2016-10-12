resource "aws_route53_record" "master_root" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.dns_zone_name}"
  type    = "A"
  alias {
    name = "dualstack.${aws_alb.main.dns_name}"
    zone_id = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "master_sub" {
  zone_id = "${var.dns_zone_id}"
  name    = "master.${var.dns_zone_name}"
  type    = "A"
  alias {
    name = "dualstack.${aws_alb.main.dns_name}"
    zone_id = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apps_root" {
  zone_id = "${var.dns_zone_id}"
  name    = "apps.${var.dns_zone_name}"
  type    = "A"
  alias {
    name = "dualstack.${aws_alb.main.dns_name}"
    zone_id = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apps_wildcard" {
  zone_id = "${var.dns_zone_id}"
  name    = "*.apps.${var.dns_zone_name}"
  type    = "A"
  alias {
    name = "dualstack.${aws_alb.main.dns_name}"
    zone_id = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}
