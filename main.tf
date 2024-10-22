#VPC
resource "aws_vpc" "TEST" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "TEST_VPC"
  }
}
#create internet gateway
resource "aws_internet_gateway" "TEST_igw" {
  vpc_id = aws_vpc.TEST.id

  tags = {
    Name = "TEST_igw"
  }
}
#create custom Route table
resource "aws_route_table" "TEST-RT" {
  vpc_id = aws_vpc.TEST.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TEST_igw.id
  }

  tags = {
    Name = "TEST_RT"
  }
}
#Create subnet1
resource "aws_subnet" "PublicSubnet1" {
  vpc_id            = aws_vpc.TEST.id
  cidr_block        = var.subnet-cidr[0]
  availability_zone = data.aws_availability_zones.available.names[0] #References data source dynamically

  tags = {
    Name = "PublicSubnet1"
  }
}
#Create Subnet2
resource "aws_subnet" "PublicSubnet2" {
  vpc_id            = aws_vpc.TEST.id
  cidr_block        = var.subnet-cidr[1]
  availability_zone = data.aws_availability_zones.available.names[1] #Reference data source

  tags = {
    Name = "PublicSubnet2"
  }
}
#Associate subnet1 with custom route table
resource "aws_route_table_association" "Publicsubnet1_association" {
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.TEST-RT.id
}
#Associate subnet2 with custom route table
resource "aws_route_table_association" "Publicsubnet2_association" {
  subnet_id      = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.TEST-RT.id
}
#Creating Auto Scaling Group - First Step
#Launch configuration
resource "aws_launch_template" "ubuntu" {
  name_prefix   = "ubuntu-"
  image_id      = "ami-06b21ccaeff8cd686"
  instance_type = var.instance_type
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance-sg.id]
  }
  user_data = base64encode(<<-EOF
                #!/bin/bash
                echo "Hello, World!" > index.html
                nohup busybox httpd -f -p 80 &
                EOF
  )
  lifecycle { #Determines how resources are created, delted or updated by referencing old resources
    create_before_destroy = true
  }
}

#Deploying Load balancer
#Create ALB - first step
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  load_balancer_type = "application"
  internal           = false
  subnets            = [data.aws_subnet.PublicSubnet1.id, data.aws_subnet.PublicSubnet2.id]
  security_groups    = [aws_security_group.alb-sg.id]
}
#Define listener for the ALB - configures ALB to listen to default http port 80 & return an error for unknown request
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404, page not found!"
      status_code  = "404"
    }
  }
}
#Create listener rules for aws_lb_listener
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
#Create target group for the ALB
resource "aws_lb_target_group" "asg" {
  name     = "tf-asg-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TEST.id
  health_check {
    path              = "/"
    protocol          = "HTTP"
    matcher           = "200"
    interval          = 15
    timeout           = 3
    healthy_threshold = 2
  }
}




