# we are using the public_ip already set in the public subnet in the networking module

# i used this to check the current aws region for the account instead of hardcoding it
data "aws_region" "current" {}

resource "aws_iam_role" "container_instance" {
  name = "${var.name_prefix}-${var.purpose}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
        }
      Action = "sts:AssumeRole"
    }]
  })
}

# i used an AWS already managed policy here instead of building a custom policy
resource "aws_iam_role_policy_attachment" "container_instance" {
  role = aws_iam_role.container_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "container_instance" {
  name = "${var.name_prefix}-${var.purpose}-instance-profile"
  role = aws_iam_role.container_instance.name
}

resource "aws_security_group" "instances" {
  name_prefix = "${var.name_prefix}-${var.purpose}-instance-sg-"
  vpc_id = var.vpc_id

  ingress {
    from_port = var.container_port
    to_port = var.container_port
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

# this part tajes care of the cluster, launch template and auto scaling group
resource "aws_ecs_cluster" "create_ecs_cluster" {
  name = "${var.name_prefix}-cluster"
}

# this data block looks for the AWS recommended ECS optimized AMI ID
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
}

# i wrote the user_data to tell an instance which ECS cluster to join
# it was written into a config file which is read on boot
# i also need to encode the user_data since we are using a launch template
locals {
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_ami.value)["image_id"]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.create_ecs_cluster.name} >> /etc/ecs/ecs.config
  EOF
  )
}

resource "aws_launch_template" "create_launch_template" {
  name_prefix = "${var.name_prefix}-${var.purpose}-lt-"
  image_id = local.ecs_ami_id
  instance_type = var.instance_type
  user_data = local.user_data

  iam_instance_profile {
    name = aws_iam_instance_profile.container_instance.name
  }

  vpc_security_group_ids = [aws_security_group.instances.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-${var.purpose}-instance"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted = true
    }
  }
}


resource "aws_autoscaling_group" "create_asg" {
  name_prefix = "${var.name_prefix}-${var.purpose}-asg-"
  vpc_zone_identifier = var.subnet_ids
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity = var.desired_capacity
  health_check_type = "EC2"

  launch_template {
    id = aws_launch_template.create_launch_template.id
    version = "$Latest"
  }

  tag {
    key = "AmazonECSManaged"
    value = "true"
    propagate_at_launch = true
  }
}

# this part handles the capacity provider linking the Auto Scaling group to ECS
# i set managed termination protection to disabled here just for demo purpose, in a production evnvironment,
# it should be enabled to avoid terminating an instance that is active
# the target capacity is in percentage, and it deals with the capacity request
# though the managed_scaling is not really useful here if our min and max size is 1
resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = "${var.name_prefix}-${var.purpose}-cap"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.create_asg.arn

    managed_scaling {
      status = "ENABLED"
      target_capacity = 100
    }

    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_cap" {
  cluster_name = aws_ecs_cluster.create_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider.name]

## might remove since it is not necessary
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
    weight = 1
  }
}

# this part is for the task, service, IAM role, and logs
module "task_iam" {
  source = "../iam"
  name_prefix = var.name_prefix
  role-use = var.purpose
  trusted_service = "ecs-tasks"
  s3_read_arn = var.s3_read_arn
  s3_write_arn = var.s3_write_arn
  secrets_read_arn = var.secrets_read_arn
}


resource "aws_iam_role" "execution" {
  name = "${var.name_prefix}-${var.purpose}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
        }
      Action = "sts:AssumeRole"
    }]
  })
}


# I used bridge as network_mode and not awsvpc which is for fargate config
resource "aws_ecs_task_definition" "task_def" {
  family = "${var.name_prefix}-${var.purpose}"
  requires_compatibilities = ["EC2"]
  network_mode = "bridge"
  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn   = module.task_iam.role_arn

  container_definitions = jsonencode([{
    name = var.purpose
    image = var.container_image
    essential = true
    cpu = var.task_cpu
    memory= var.task_memory
    portMappings = [{
      containerPort = var.container_port
      hostPort = var.container_port
      protocol = "tcp"
    }]
  }])
}

# the depends_on means that the capacity_provider must exist before the service runs, else it will fail
resource "aws_ecs_service" "create_ecs_service" {
  name = "${var.name_prefix}-${var.purpose}"
  cluster = aws_ecs_cluster.create_ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count = var.desired_count
  force_new_deployment = true

  depends_on = [aws_ecs_cluster_capacity_providers.cluster_cap]
}