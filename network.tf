resource "aws_internet_gateway" "poc_igw" {
    vpc_id = "${aws_vpc.poc_vpc.id}"

    tags = {
      "name" = "poc_igw"
    }
}

resource "aws_route_table" "poc_pub_crt" {
    vpc_id = "${aws_vpc.poc_vpc.id}"

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.poc_igw.id}"
    } 

    tags = {
      "name" = "poc_pub_crt"
    }
}

resource "aws_route_table" "poc_priv_crt" {
  vpc_id = "${aws_vpc.poc_vpc.id}"
  tags = {
    Name = "poc_priv_crt"
  }
}

resource "aws_route_table_association" "poc_crta_pub_subnet" {
    count = "${length(var.public_subnet)}"
    subnet_id = "${element(aws_subnet.poc_public.*.id, count.index)}"
    route_table_id = aws_route_table.poc_pub_crt.id
  
}

resource "aws_route_table_association" "poc_crta_priv_subnet" {
    count = "${length(var.private_subnet)}"
    subnet_id = "${element(aws_subnet.poc_private.*.id, count.index)}"
    route_table_id = aws_route_table.poc_priv_crt.id
  
}

# Security group for private subnets
resource "aws_security_group" "ssh_allowed" {
    vpc_id = aws_vpc.poc_vpc.id

    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 0
      protocol = -1
      self = false
      to_port = 0
    }

    ingress {
      from_port = 22
      protocol = "tcp"
      to_port = 22
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# Security group for public subnets and rhel instance on sub2
resource "aws_security_group" "public_sg" {
    vpc_id = aws_vpc.poc_vpc.id

    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 0
      protocol = -1
      self = false
      to_port = 0
    }

    ingress {
      from_port = 22
      protocol = "tcp"
      to_port = 22
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port = 0
        protocol = -1
        self = false
        to_port = 0
    }
  
}