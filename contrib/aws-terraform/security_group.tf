resource "aws_security_group" "ose" {
  name        = "ose-nodes"
  description = "Allow openshift enterprise traffic"
  vpc_id      = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "ose_in_public_tcp" {
  type              = "ingress"
  from_port         = "${element(var.public_tcp_ports, count.index)}"
  to_port           = "${element(var.public_tcp_ports, count.index)}"
  count             = "${length(var.public_tcp_ports)}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.ose.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ose_in_internal_tcp" {
  type                     = "ingress"
  from_port                = "${element(var.internal_tcp_ports, count.index)}"
  to_port                  = "${element(var.internal_tcp_ports, count.index)}"
  count                    = "${length(var.internal_tcp_ports)}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ose.id}"
  source_security_group_id = "${aws_security_group.ose.id}"
}

resource "aws_security_group_rule" "ose_in_internal_udp" {
  type                     = "ingress"
  from_port                = "${element(var.udp_ports, count.index)}"
  to_port                  = "${element(var.udp_ports, count.index)}"
  count                    = "${length(var.udp_ports)}"
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.ose.id}"
  source_security_group_id = "${aws_security_group.ose.id}"
}

resource "aws_security_group_rule" "ose_out_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ose.id}"
}
