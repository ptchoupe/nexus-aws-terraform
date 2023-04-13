# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "nexus_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "nexus_key" {
  key_name   = "nexus_key_pair"
  public_key = tls_private_key.nexus_key.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.nexus_key.key_name}.pem"
  content  = tls_private_key.nexus_key.private_key_pem
}

# launch the ec2 instance and install nexus
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.nexus_ec2_security_group.id]
  key_name               = aws_key_pair.nexus_key.key_name
  # user_data            = file("install-nexus.sh")

  tags = {
    Name = "Nexus Server and ssh security group"
  }
}

# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local_file.ssh_key.filename)
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy the install-nexus.sh file from your computer to the ec2 instance 
  /* provisioner "file" {
    source      = "install-nexus.sh"
    destination = "/tmp/install-nexus.sh"
  } */

  # set permissions and run the install_nexus.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",

      ## Install Java 8:
      "sudo yum install java-1.8.0-openjdk -y",

      # download the latest version of nexus
      "sudo wget https://download.sonatype.com/nexus/3/nexus-3.45.0-01-unix.tar.gz",

      "sudo yum upgrade -y",
      # Extract the downloaded archive file
      "tar -xvzf nexus-3.45.0-01-unix.tar.gz",
      "rm -f nexus-3.45.0-01-unix.tar.gz",
      "sudo mv nexus-3.45.0-01 nexus",

      # Start Nexus and check status
      "sh ~/nexus/bin/nexus start",
      "sh ~/nexus/bin/nexus status",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance]
}
