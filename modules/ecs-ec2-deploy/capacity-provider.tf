# # ECS Capacity Provider
# resource "aws_ecs_capacity_provider" "test" {
#   name = "ba-ecs_capacity_provider-${random_string.random.result}" 
  
#   auto_scaling_group_provider {
#     auto_scaling_group_arn      = aws_autoscaling_group.ecs-ec2-asg.arn
#     # managed_termination_protection = "ENABLED"

#     managed_scaling {
#       maximum_scaling_step_size = 1 #The maximum number of CIs ECS will scale in or scale out at one time.
#       minimum_scaling_step_size = 1 #The minimum number [...]
#       status                    = "ENABLED"
#       target_capacity           = 80 # M/Nx100=target_capacity
#     }
#   }
# }
