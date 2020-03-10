provider "aws" {
  region     = var.aws_region
}
provider "random" {
  alias      = "rd"
}

### Peering cluster VPC with the master VPC 
provider "aws" {
  alias  = "master"
  region     = var.aws_region
}

data "aws_vpc" "master" {
  cidr_block = "172.22.0.0/16"
}

data "aws_caller_identity" "master" {
  provider = aws.master
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "master" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = data.aws_vpc.master.id
  peer_owner_id = data.aws_caller_identity.master.account_id
  peer_region   = var.aws_region
  auto_accept   = false
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "master" {
  provider                  = aws.master
  vpc_peering_connection_id = aws_vpc_peering_connection.master.id
  auto_accept               = true
}

# Creating routes between vpc
data "aws_route_tables" "main" {
  vpc_id= aws_vpc.main.id
  depends_on = [aws_route_table.private ]
}

data "aws_route_tables" "master" {
  provider    = aws.master
  vpc_id      = data.aws_vpc.master.id
}

resource "aws_route" "main_to_master" {
  route_table_id            = aws_vpc.main.main_route_table_id
  destination_cidr_block    = data.aws_vpc.master.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.master.id
    depends_on                = [aws_subnet.public]
}

# resource "aws_route" "master_to_main" {
#   provider                  = aws.master
#   route_table_id            = flatten(data.aws_route_tables.master.ids)[count.index]
#   destination_cidr_block    = aws_vpc.main.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.master.id
#   depends_on                = [ aws_vpc_peering_connection.master,
#                                 aws_route.main_to_master
#    ]
# }

##########################################################

# NETWORK

resource "aws_vpc" "main" {
  cidr_block = "172.20.0.0/16"
}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

resource "aws_subnet" "private" { 
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
}

# IGW for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ba-ecs-ec2"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  count      = var.az_count
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "gw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
}

# Create a new route table for the private subnets
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }
}

# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
  depends_on = [
    aws_subnet.private,
  ]
}

##########################################################

# ECS INSTANCE ROLE
resource "aws_iam_role" "ecs-instance-role" {
  name = "ba-ecs-instance-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-instance-policy.json

}

data "aws_iam_policy_document" "ecs-instance-policy" {
   statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ec2.amazonaws.com"]
  }
 }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
   role = aws_iam_role.ecs-instance-role.name
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

##########################################################
# ECS SERVICE ROLE
resource "aws_iam_role" "ecs-service-role" {
  name = "ba-ecs-service-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-service-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ecs.amazonaws.com"]
  }
 }
}
##########################################################

# IAM INSTANCE PROFILE
resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ba-ecs-instance-profile"
  path = "/"
  role = aws_iam_role.ecs-instance-role.id
  provisioner "local-exec" {
  command = "sleep 60"
 }
}
##########################################################

#SECURITY

# Allow monitoring instance inbound access for influxdb queries and telegraf
resource "aws_security_group_rule" "monitoring_a" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8086
  to_port         = 8086
  protocol        = "tcp"
  source_security_group_id = aws_security_group.alb.id
}
resource "aws_security_group_rule" "monitoring_b" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8186
  to_port         = 8186
  protocol        = "tcp"
  source_security_group_id = aws_security_group.alb.id
}
resource "aws_security_group_rule" "monitoring_c" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8086
  to_port         = 8086
  protocol        = "tcp"
  source_security_group_id = aws_security_group.ecs_ec2_sg.id
}
resource "aws_security_group_rule" "monitoring_d" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8186
  to_port         = 8186
  protocol        = "tcp"
  source_security_group_id = aws_security_group.ecs_ec2_sg.id
}

data "aws_instance" "deploy" {
 filter {
    name   = "tag:Name"
    values = ["ba_ecsdeploy"]
  }
}
data "aws_instance" "trafficgen" {
 filter {
    name   = "tag:Name"
    values = ["ba_ecstrafficgen"]
  }
}
data "aws_instance" "monitoring" {
 filter {
    name   = "tag:Name"
    values = ["ba-ecsmonitoring"]
  }
  filter {
    name   = "instance-type"
    values = ["t2.medium"]
  }
}

resource "aws_security_group" "ecs_ec2_sg" {
  name        = "ba-ecs-ec2-grp"
  description = "allow access to all ports"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    security_groups = ["${aws_security_group.alb.id}"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 8086
    to_port     = 8086
    cidr_blocks = ["${data.aws_instance.monitoring.public_ip}/32"] # Allow influxDB queries on monitoring instance
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [ aws_vpc_peering_connection_accepter.master ]
}

resource "aws_security_group" "alb" {
  name        = "ba-ecs-alb-grp"
  description = "allow access to 3100 8086"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 3100
    to_port         = 3100
    cidr_blocks = ["${data.aws_instance.trafficgen.public_ip}/32",
                   "${data.aws_instance.deploy.public_ip}/32"
                  ] # Allow communication with traffic gen on main instance
  }
  
  ingress {
    protocol    = "TCP"
    from_port   = 8086
    to_port     = 8086
    cidr_blocks = ["${data.aws_instance.monitoring.public_ip}/32"] # Allow influxDB queries on monitoring instance
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [ aws_vpc_peering_connection_accepter.master ]
}

##########################################################

#EXECUTION ROLE

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

##########################################################

# AWS ECS-CLUSTER
resource "aws_ecs_cluster" "cluster" {
  name = "ba-ecs-ec2-cluster"
  # capacity provider name must be hardcoded, otherwise it will raise false error "already existing, can't create"
  capacity_providers = ["ba-ecs_capacity_provider-${random_string.random.result}"]  
  depends_on = [
    aws_ecs_capacity_provider.test,
    aws_autoscaling_group.ecs-ec2-asg
  ] 
}

###########################################################

# AWS ECS-SERVICE
resource "aws_ecs_service" "service" {
  cluster                = aws_ecs_cluster.cluster.id                                
  desired_count          = 1                                                        
  launch_type            = "EC2"                                                    
  name                   = "stresstestapp"                                         
  task_definition        = aws_ecs_task_definition.app.arn       
  load_balancer {
    container_name       = "stresstestapp"
    container_port       = var.app_port
    target_group_arn     = aws_lb_target_group.lb_target_group.arn       
 }
  depends_on              = [aws_lb_listener.lb_listener]
  health_check_grace_period_seconds = 600 # prevent task from being deregistered when we apply full stress on the task and health check fails  
}

##########################################################

# LOAD BALANCER

resource "aws_lb" "loadbalancer" {
  name                = "ba-ecs-ec2-alb-name"
  subnets             = flatten([aws_subnet.public.*.id])  # public subnets
  security_groups     = [aws_security_group.alb.id] 
  depends_on = [
    aws_subnet.public,
  ]
  provisioner "local-exec" {
    command = "echo ${aws_lb.loadbalancer.dns_name} > ../../lb_addr/loadbalancer_address"
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name        = "ba-ecs-ec2-alb-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  deregistration_delay = 10
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.loadbalancer.id
  port              = var.app_port
  protocol          = "HTTP"
  
  default_action {
    target_group_arn = aws_lb_target_group.lb_target_group.id
    type             = "forward"
  }
}

##########################################################

# ECS TASK DEF
data "aws_caller_identity" "current" {

}

resource "aws_ecs_task_definition" "app" {
  family                   = "stresstestapp"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.ec2_cpu},
    "image": "${data.aws_caller_identity.current.account_id}.${var.app_image}",
    "memory": ${var.ec2_memory},
    "name": "stresstestapp",
    "networkMode": "bridge",
    "portMappings": [
      {
        "containerPort": ${var.app_port}
      },
      {
        "containerPort": 8186
      }
    ]
  },
  {
    "cpu": ${var.ec2_cpu},
    "image": "${data.aws_caller_identity.current.account_id}.${var.telegraf_image}",
    "memory": ${var.ec2_memory},
    "name": "telegraf",
    "networkMode": "bridge",
    "portMappings": [
      {
        "containerPort": 8086        
      }
    ]
  }
]
DEFINITION
}

####################

# ASG 

resource "aws_autoscaling_group" "ecs-ec2-asg" {
  name                 = "ba-ecs_capacity_provider-${random_string.random.result}"
  max_size             = 4
  min_size             = 1
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

######################

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
}

# LAUNCH CONF

resource "aws_launch_configuration" "container_instance" {
  name_prefix   = "ba-ecs-ci-"
  image_id      = data.aws_ami.amifiltering.id
  instance_type = "c5.2xlarge"
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

#################

# ECS Capacity Provider

resource "aws_ecs_capacity_provider" "test" {
  name = "ba-ecs_capacity_provider-${random_string.random.result}" 
  
  auto_scaling_group_provider {
    auto_scaling_group_arn      = aws_autoscaling_group.ecs-ec2-asg.arn
    # managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1 #The maximum number of CIs ECS will scale in or scale out at one time.
      minimum_scaling_step_size = 1 #The minimum number [...]
      status                    = "ENABLED"
      target_capacity           = 80 # M/Nx100=target_capacity
    }
  }
}

# # ECS Svc AS

# module "svc-scaling" {
#   source          = "./modules/svc-scaling"
#   cluster_name    = aws_ecs_cluster.cluster.name
#   service_name    = aws_ecs_service.service.name
#   alarm_name      = "ba_cpu_stressapp"
#   scale_policy_name_prefix = "ba_stressapp"
#   min_capacity    = "1"
#   max_capacity    = "50"
#   statistic       = "Average"
#   scale_up_adjustment = "100"
#   scale_down_adjustment = "-50"
#   threshold_up = "90"
#   threshold_down = "30"
# }
# module "svc-tracking-scaling" {
#   source          = "./modules/svc-tracking-scaling"
#   cluster_name    = aws_ecs_cluster.cluster.name
#   service_name    = aws_ecs_service.service.name
#   alarm_name      = "ba_cpu_stressapp"
#   scale_policy_name_prefix = "ba_stressapp"
#   min_capacity    = "1"
#   max_capacity    = "50"
#   ecs_autoscale_role_arn = module.svc-scaling.ecs_autoscale_role_arn
# }

module "svc-scaling-mem" {
  source          = "./modules/svc-scaling"
  cluster_name    = aws_ecs_cluster.cluster.name
  service_name    = aws_ecs_service.service.name
  alarm_name      = "ba_mem_stressapp"
  scale_policy_name_prefix = "ba_stressapp"
  min_capacity    = "1"
  max_capacity    = "50"
  statistic       = "Average"
  metric_name     = "MemoryUtilization"
  scale_up_adjustment = "100"
  scale_down_adjustment = "-50"
  threshold_up = "90"
  threshold_down = "30"
}

module "svc-tracking-scaling-mem" {
  source          = "./modules/svc-tracking-scaling-mem"
  cluster_name    = aws_ecs_cluster.cluster.name
  service_name    = aws_ecs_service.service.name
  alarm_name      = "ba_mem_stressapp"
  scale_policy_name_prefix = "ba_stressapp"
  min_capacity    = "1"
  max_capacity    = "50"
  ecs_autoscale_role_arn = module.svc-scaling-mem.ecs_autoscale_role_arn
}
