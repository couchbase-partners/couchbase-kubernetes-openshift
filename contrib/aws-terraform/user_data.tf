data "template_file" "user_data" {
  template = "${file("user_data.tmpl.yaml")}"

  vars {
    ssh_user = "${lookup(var.ssh_user,var.operating_system)}"
  }
}
