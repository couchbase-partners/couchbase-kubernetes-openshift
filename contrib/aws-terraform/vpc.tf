resource "aws_subnet" "main" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "172.18.1.0/24"
  availability_zone = "${var.aws_availability_zone}"
}

resource "aws_route" "default" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "ose-igw"
  }
}

resource "aws_vpc" "default" {
  cidr_block           = "172.18.0.0/16"
  enable_dns_hostnames = "true"

  tags {
    Name = "ose-vpc"
  }
}
