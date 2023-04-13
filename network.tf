# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "nexus default vpc"
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "nexus default subnet"
  }
}

# create security group for the ec2 instance
resource "aws_security_group" "nexus_ec2_security_group" {
  name        = "ec2 nexus security group"
  description = "allow access on ports 8081 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  # allow access on port 8081 for nexus Server
  ingress {
    description = "http proxy access"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow access on port 22 ssh connection
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Nexus server security group"
  }
}