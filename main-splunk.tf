# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "splunk VPC"
  }
}


# Create Web Public Subnet
resource "aws_subnet" "web-subnet" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name = "splunk-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "splunk IGW"
  }
}

# Create Web layber route table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.my-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "WebRT"
  }
}

# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet.id
  route_table_id = aws_route_table.web-rt.id
}


# Create Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "splunk security group"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh from VPC splunk server"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from VPC splunk forwader"
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Open port for JFOG
  ingress {
    description = "ssh from VPC splunk forwader"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "splunk-SG"
  }
}


#data for amazon linux
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

#create ec2 instances
resource "aws_instance" "splunk-server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.web-subnet.id
  vpc_security_group_ids = ["${aws_security_group.web-sg.id}"]
  key_name               = aws_key_pair.ec2-key.key_name
  #user_data              = file("splunk_script.sh")
  # Set the instance's root volume to 30 GB
  root_block_device {
    volume_size = 30
  }


  tags = {
    Name        = "splunk-server"
    owner       = "splunk"
    Environment = "dev"
  }

    provisioner "file" {
    source      = "${path.module}/scripts_for_splunk_server"
    destination = "/home/ec2-user/"

    connection {
      type = "ssh"
      user = "ec2-user"
      #private_key = file("splunkkey.pem")
      private_key = file(local_file.ssh_key.filename)
      host        = self.public_ip
      timeout     = "1m"
    }
  }
}

resource "aws_instance" "splunk-forwarder" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.web-subnet.id
  vpc_security_group_ids = ["${aws_security_group.web-sg.id}"]
  key_name               = aws_key_pair.ec2-key.key_name
  #user_data              = file("splunk_forwarder_script.sh")
  # Set the instance's root volume to 30 GB
  root_block_device {
    volume_size = 30
  }

  tags = {
    Name        = "splunk-forwarder"
    owner       = "splunk"
    Environment = "dev"
  }

  provisioner "file" {
    source      = "${path.module}/scripts_for_splunk_forwarder"
    destination = "/home/ec2-user/"

    connection {
      type = "ssh"
      user = "ec2-user"
      #private_key = file("splunkkey.pem")
      private_key = file(local_file.ssh_key.filename)
      host        = self.public_ip
      timeout     = "1m"
    }
  }

  provisioner "file" {
    source      = "${path.module}/script_for_forwarder_config"
    destination = "/home/ec2-user/"

    connection {
      type = "ssh"
      user = "ec2-user"
      #private_key = file("splunkkey.pem")
      private_key = file(local_file.ssh_key.filename)
      host        = self.public_ip
      timeout     = "1m"
    }
  }
}

# just install the splunk forwader script
resource "null_resource" "install_splunk_forwarder" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local_file.ssh_key.filename)
    host        = aws_instance.splunk-forwarder.public_ip
  }
  # set permissions and run the  file
  provisioner "remote-exec" {
    inline = [
      "ls",
      "pwd",
      # Install httpd
      "sh scripts_for_splunk_forwarder/splunk_forwarder_script.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.splunk-forwarder]
}

# just install the splunk server script
resource "null_resource" "install_splunk_server" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local_file.ssh_key.filename)
    host        = aws_instance.splunk-server.public_ip
  }
  # set permissions and run the  file
  provisioner "remote-exec" {
    inline = [
      "ls",
      "pwd",
      # Install httpd
      "sh scripts_for_splunk_server/splunk_script.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.splunk-server]
}


# Wait for scripts to be installed in the first two null_resources before installing the last null_resource.
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local_file.ssh_key.filename)
    host        = aws_instance.splunk-forwarder.public_ip
  }
  # set permissions and run the  file
  provisioner "remote-exec" {
    inline = [
      "ls",
      "pwd",
      # Install httpd
      "sh script_for_forwarder_config/apache_installation.sh",

      # Install JFROG
      "sh script_for_forwarder_config/jfrog_installation_from_scratch.sh",

      # Create the users
      "sudo sh script_for_forwarder_config/create_users.sh script_for_forwarder_config/user_informations.txt",

      # End configuration on forwader
      "sudo sh script_for_forwarder_config/config_host_forwader.sh ${aws_instance.splunk-server.public_ip}",
    ]
  }

  # wait the 2 null resource that install splunk and splunk forwarder
  depends_on = [null_resource.install_splunk_server, null_resource.install_splunk_forwarder]
}

