#subnet data source
data "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.TEST.id
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}
data "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.TEST.id
  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]
  }
}
#Availability Zone data source
data "aws_availability_zones" "available" {
  state = "available"
}