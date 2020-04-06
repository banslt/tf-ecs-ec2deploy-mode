data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
}

# LAUNCH CONF

resource "aws_launch_configuration" "container_instance" {
  name_prefix   = "ba-ecs-ci-"
  image_id      = data.aws_ami.amifiltering.id
  instance_type = "c5.xlarge"
  user_data = data.template_file.user_data.rendered
  iam_instance_profile   = aws_iam_instance_profile.ecs-instance-profile.name
  security_groups = [aws_security_group.ecs_ec2_sg.id,]
  key_name               = "ba_keypair"
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "amifiltering" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2018.03.0.20181129-x86_64-gp2"]
  }
  owners  = ["amazon"]
}

# ASG 
resource "aws_autoscaling_group" "ecs-ec2-asg" {
  name                 = "ba-ecs_capacity_provider-1"
  max_size             = 3
  min_size             = 1
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.container_instance.name
  vpc_zone_identifier  = flatten([aws_subnet.private.*.id]) # location where the CIs will be deployed
  tags = [
    {
      key                 = "Org"
      value               = "sre"
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = "ba"
      propagate_at_launch = true
    },
    {
      key                 = "Customer"
      value               = "symphony"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "ba-ci-${random_string.random.result}"
      propagate_at_launch = true
    }
  ]
}

resource "random_string" "random" {
  provider = random.rd
  length   = 4
  special  = false
  number   = false
  upper    = false
}
