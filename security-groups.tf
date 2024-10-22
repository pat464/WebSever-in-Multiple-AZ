#Create Autoscaling group
resource "aws_autoscaling_group" "web" {
  vpc_zone_identifier = [data.aws_subnet.PublicSubnet1.id, data.aws_subnet.PublicSubnet2.id]
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 5
  launch_template {
    id      = aws_launch_template.ubuntu.id
    version = "$Latest"
  }
}
#ALB Security Group
resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.TEST.id # references data source for the VPC
  #Allow inbound HTTP traffic from anywhere
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
#Security group for the EC2 instance
resource "aws_security_group" "instance-sg" {
  name        = "instance-sg"
  description = "Security group for the EC2 instance"
  vpc_id      = aws_vpc.TEST.id
  #Allow inbound HTTP traffic from the ALB SG
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  #Allow inbound SSH
  ingress {
    description = "SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}