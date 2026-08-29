# The EC2 instance first needs an IAM role to grant permision to reach out to other AWS services
# so, i used the IAm nodule here
module "iam" {
  source = "../iam"
  name_prefix = var.name_prefix
  role-use = var.purpose
  trusted_service = "ec2"
}

# for the ingress, the from & to_port are a single port;
# i used the egress to allow every traffic going out
# the -1 value means that all protocols, either tcp, udp and others are allowed
# also, the 0 used for the from_port and to_port under egress are placeholders since the protocol allows all traffic going out
# the network protocol
resource "aws_security_group" "create_sg" {
  name_prefix = "${var.name_prefix}-${var.purpose}-sg-"
  vpc_id = var.vpc_id

  ingress {
    from_port = var.ingress_port
    to_port = var.ingress_port
    protocol = "tcp"
    cidr_blocks = [var.allowed_ingress_cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# I used this to get the latest Amazon Linux image instead of hardcoding it
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "create_instance" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.create_sg.id]
  iam_instance_profile = module.iam.instance_profile_name

  tags = {
    Name = "${var.name_prefix}-${var.purpose}"
  }

  root_block_device {
    encrypted = true
  }
}