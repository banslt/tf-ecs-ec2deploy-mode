output "alb_hostname" {
  value = "${aws_lb.loadbalancer.dns_name}"
}

output "aws_ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "aws_ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "aws_iam_role_ecs_asg_role_arn" {
  value = aws_iam_role.ecs-autoscale-role.arn
}

output "aws_alb_target_group_app_arn_suffix" {
  value = aws_lb_target_group.lb_target_group.arn_suffix 
}

output "aws_alb_arn_suffix" {
  value = aws_lb.loadbalancer.arn_suffix 
}
