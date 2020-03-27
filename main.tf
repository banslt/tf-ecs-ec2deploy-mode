provider "aws" {
  region     = "us-east-2"
}
provider "random" {
  alias      = "rd"
}
provider "aws" {
  alias  = "master"
  region     = "us-east-2"
}

module "ecs-ec2-deploy" {
  source = "./modules/ecs-ec2-deploy"
}

module "svc-scaling" {
  source          = "./modules/svc-scaling"
  cluster_name    = module.ecs-ec2-deploy.aws_ecs_cluster_name
  service_name    = module.ecs-ec2-deploy.aws_ecs_service_name
  alarm_name      = "ba_cpu_stressapp"
  scale_policy_name_prefix = "ba_cpu_stressapp"
  ecs-autoscale-role_arn = module.ecs-ec2-deploy.aws_iam_role_ecs_asg_role_arn
  statistic       = "Average"
  scale_up_adjustment = "100"
  scale_down_adjustment = "-50"
  threshold_up = "90"
  threshold_down = "30"
  dims = [ {name= "ClusterName",value=module.ecs-ec2-deploy.aws_ecs_cluster_name }
          ,{name= "ServiceName",value=module.ecs-ec2-deploy.aws_ecs_service_name }
         ]
}
module "svc-tracking-scaling" {
  source          = "./modules/svc-tracking-scaling"
  cluster_name    = module.ecs-ec2-deploy.aws_ecs_cluster_name
  service_name    = module.ecs-ec2-deploy.aws_ecs_service_name
  alarm_name      = "ba_cpu_tracking_stressapp"
  scale_policy_name_prefix = "ba_cpu_tracking_stressapp"
  min_capacity    = "1"
  max_capacity    = "50"
}


module "svc-scaling-lb-rsp-time" {
  source          = "./modules/svc-scaling"
  cluster_name    = module.ecs-ec2-deploy.aws_ecs_cluster_name
  service_name    = module.ecs-ec2-deploy.aws_ecs_service_name
  alarm_name      = "ba_lb-rsp-time_stressapp"
  scale_policy_name_prefix = "ba_lb-rsp-time_stressapp"
  statistic       = "Average"
  namespace       = "AWS/ApplicationELB"
  metric_name     = "TargetResponseTime"
  scale_up_adjustment = "100"
  scale_down_adjustment = "-50"
  evaluation_periods = 1
  datapoints_to_alarm_up = 1
  datapoints_to_alarm_down = 1
  threshold_up    = "0.200"
  threshold_down  = "0"
  ecs-autoscale-role_arn = module.ecs-ec2-deploy.aws_iam_role_ecs_asg_role_arn
  dims = [ {name= "TargetGroup" ,value=module.ecs-ec2-deploy.aws_alb_target_group_app_arn_suffix }
          ,{name= "LoadBalancer",value=module.ecs-ec2-deploy.aws_alb_arn_suffix }
         ]
  }

module "svc-tracking-scaling-lb-rsp-time" {
  source          = "./modules/svc-tracking-scaling-custom"
  cluster_name    = module.ecs-ec2-deploy.aws_ecs_cluster_name
  service_name    = module.ecs-ec2-deploy.aws_ecs_service_name
  alarm_name      = "ba_lb-rsp-time_tracking_stressapp"
  scale_policy_name_prefix = "ba_lb-rsp-time_tracking_stressapp"
  namespace       = "AWS/ApplicationELB"
  metric_name     = "TargetResponseTime"
  min_capacity    = "1"
  max_capacity    = "50"
  target_value    = "0.200" 
  disable_scale_in= true
  dims = [ {name= "TargetGroup" ,value=module.ecs-ec2-deploy.aws_alb_target_group_app_arn_suffix }
          ,{name= "LoadBalancer",value=module.ecs-ec2-deploy.aws_alb_arn_suffix }
         ]
}

# module "svc-scaling-mem" {
#   source          = "./modules/svc-scaling"
#   cluster_name    = module.ecs-ec2-deploy.aws_ecs_cluster_name
#   service_name    = module.ecs-ec2-deploy.aws_ecs_service_name
#   alarm_name      = "ba_mem_stressapp"
#   scale_policy_name_prefix = "ba_stressapp"
#   min_capacity    = "1"
#   max_capacity    = "50"
#   statistic       = "Maximum"
#   metric_name     = "MemoryUtilization"
#   scale_up_adjustment = "100"
#   scale_down_adjustment = "-50"
#   threshold_up = "90"
#   threshold_down = "30"
#   ecs-autoscale-role_arn = module.ecs-ec2-deploy.aws_iam_role_ecs_asg_role_arn
# }

# module "svc-tracking-scaling-mem" {
#   source          = "./modules/svc-tracking-scaling-mem"
#   cluster_name    = module.ecs-ec2-deploy.aws_ecs_cluster_name
#   service_name    = module.ecs-ec2-deploy.aws_ecs_service_name
#   alarm_name      = "ba_mem_stressapp"
#   scale_policy_name_prefix = "ba_stressapp"
#   min_capacity    = "1"
#   max_capacity    = "50"
#   statistic       = "Maximum"
# }
