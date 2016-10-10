resource "aws_instance" "ose-master" {
  ami                         = "${lookup(var.aws_ami,format("%s-%s",var.operating_system, var.aws_region))}"
  instance_type               = "${var.master_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.ose.id}"]
  availability_zone           = "${var.aws_availability_zone}"
  subnet_id                   = "${aws_subnet.main.id}"
  key_name                    = "${var.keypair}"
  associate_public_ip_address = "true"
  count                       = "${var.num_master}"

  tags {
    Name          = "${var.cluster_id}-master"
    clusterid     = "${var.cluster_id}"
    created-by    = "${var.cluster_creator}"
    environment   = "${var.cluster_env}"
    host-type     = "master"
    sub-host-type = "default"
  }

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.ebs_root_block_size}"
  }

  user_data = "${data.template_file.user_data.rendered}"
}
