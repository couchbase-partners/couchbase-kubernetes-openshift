resource "aws_security_group" "lb_sg" {
  description = "controls access to the public Openshift ELB"

  vpc_id = "${aws_vpc.default.id}"
  name   = "tf-ecs-lbsg"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8443
    to_port     = 8443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_alb_target_group" "http-router" {
  name     = "http-router"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default.id}"
}

resource "aws_alb_target_group" "https-router" {
  name     = "https-router"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${aws_vpc.default.id}"
}

resource "aws_alb_target_group" "https-master" {
  name     = "https-master"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = "${aws_vpc.default.id}"

  health_check {
    protocol = "HTTPS"
    path     = "/healthz/ready"
  }
}

resource "aws_alb" "main" {
  name            = "ose-public"
  subnets         = ["${aws_subnet.main.*.id}"]
  security_groups = ["${aws_security_group.lb_sg.id}"]
}

resource "aws_alb_listener" "http-router" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.http-router.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "https-router" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "arn:aws:acm:eu-west-1:511419813097:certificate/4ebd9c6b-8a4c-4908-ac38-4638ac845cf5"

  default_action {
    target_group_arn = "${aws_alb_target_group.https-router.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "https-master" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "arn:aws:acm:eu-west-1:511419813097:certificate/4ebd9c6b-8a4c-4908-ac38-4638ac845cf5"

  default_action {
    target_group_arn = "${aws_alb_target_group.https-master.id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "http-router" {
  target_group_arn = "${aws_alb_target_group.http-router.arn}"
  target_id        = "${element(aws_instance.ose-node-infra.*.id,count.index)}"
  port             = 80
  count            = "${var.num_node_infra}"
}

resource "aws_alb_target_group_attachment" "https-router" {
  target_group_arn = "${aws_alb_target_group.https-router.arn}"
  target_id        = "${element(aws_instance.ose-node-infra.*.id,count.index)}"
  port             = 443
  count            = "${var.num_node_infra}"
}

resource "aws_alb_target_group_attachment" "https-master" {
  target_group_arn = "${aws_alb_target_group.https-master.arn}"
  target_id        = "${element(aws_instance.ose-master.*.id,count.index)}"
  port             = 8443
  count            = 1
}
