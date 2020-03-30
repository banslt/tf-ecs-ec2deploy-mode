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

# AWS ECS-SERVICE
resource "aws_ecs_service" "service" {
  cluster                = aws_ecs_cluster.cluster.id
  desired_count          = 10
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
