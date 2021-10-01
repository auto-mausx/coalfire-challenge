resource "aws_vpc" "poc_vpc" {
    cidr_block = "10.1.0.0/16"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    instance_tenancy = "default"

    tags = {
        name = "poc_vpc"
    }
}

resource "aws_subnet" "poc_public" {
    count = "${length(var.public_subnet)}"
    vpc_id = "${aws_vpc.poc_vpc.id}"
    cidr_block = "${var.public_subnet[count.index]}"
    availability_zone = "${var.availability_zones[count.index]}"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "poc_private" {
    count = "${length(var.private_subnet)}"
    vpc_id = "${aws_vpc.poc_vpc.id}"
    cidr_block = "${var.private_subnet[count.index]}"
    availability_zone = "${var.availability_zones[count.index]}"
    map_public_ip_on_launch = false
}