# Instance that lives in sub2
resource "aws_instance" "rhel" {
  ami = "${lookup(var.ami, var.AWS_REGION)}"
  instance_type = "t2.micro"
  availability_zone = "${var.availability_zones[1]}"

  subnet_id = "${aws_subnet.poc_public[1].id}"

  vpc_security_group_ids = [ "${aws_security_group.public_sg.id}" ]

  key_name = aws_key_pair.login.key_name
  
  tags = {
    "name" = "rhel"
  }

}

# 20GB storage for the instance in sub2
resource "aws_ebs_volume" "ebs" {
    availability_zone = "${var.availability_zones[1]}"
    size = 20

    tags = {
      "name" = "rhelEBS"
    }
}

# the resource that does the attaching
resource "aws_volume_attachment" "ebs_att" {
    device_name = "/dev/sdh"
    volume_id = aws_ebs_volume.ebs.id
    instance_id = aws_instance.rhel.id
  
}

# Template to create autoscaling group from
resource "aws_launch_template" "asg_lt" {
    name_prefix = "poc_lt"
    image_id = "${var.ami.us-east-1}"
    instance_type = "t2.micro"
    key_name = aws_key_pair.login.key_name
    # ensure this is only allows ssh, not public traffic
    vpc_security_group_ids = [ "${aws_security_group.ssh_allowed.id}" ]
    # add ebs volumes to instances
    block_device_mappings {
       ebs {
         volume_size = 20
         delete_on_termination = true #for demo cleanup only
       }
        device_name = "/dev/sdf"
    }
    # Install apache
    user_data = "${base64encode(<<-EOF
    #!bin/bash
    sudo dnf install httpd
    sudo systemctl enable httpd.service
    sudo systemctl start httpd.service
    
    sudo echo "Hello World!" > /var/www/html/index.html

    EOF
    )}"
}

resource "aws_autoscaling_group" "poc_asg" {

    desired_capacity = 2
    max_size = 6
    min_size = 2
    vpc_zone_identifier = [ "${aws_subnet.poc_private[1].id}" ]
    target_group_arns = [ "${aws_alb_target_group.instance_tg.arn}" ]
    
  
  launch_template {
    id = aws_launch_template.asg_lt.id
    version = "$Latest"
  }
}

# Application load balancer
resource "aws_alb" "asg-alb" {
    name = "poc-alb"
    internal = false
    security_groups = [aws_security_group.ssh_allowed.id]
    subnets = [aws_subnet.poc_public[1].id, aws_subnet.poc_public[0].id]
    
    load_balancer_type = "application"

    enable_deletion_protection = false

}

resource "aws_alb_target_group" "instance_tg" {
    name = "poc-lb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.poc_vpc.id
}

resource "aws_lb_listener" "asg_lb_listener" {
    load_balancer_arn = aws_alb.asg-alb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.instance_tg.arn
    }
  
}

resource "aws_s3_bucket" "storage" {
    bucket = "poc-coalfire-bucket-060892"
    acl = "private"

    lifecycle_rule {
      id = "log"
      enabled = true

      prefix = "log/"

      tags = {
          rule = "log"
          autoclean = "true"
      }

      expiration {
          days = 90
      }
    }

    lifecycle_rule {
      id = "images"
      enabled = true

      prefix = "images/"

      tags = {
        rule = "images"
        autoclean = "false"
      }

       transition {
        days          = 90
        storage_class = "GLACIER"
    }
    }
  
}

resource "aws_key_pair" "login" {
  key_name = "poc-key"
  public_key = file(var.key_path)
  
}