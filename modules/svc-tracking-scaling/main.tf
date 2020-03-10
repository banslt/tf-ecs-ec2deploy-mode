resource "aws_appautoscaling_policy" "scale" {
  name               = "${var.scale_policy_name_prefix}-scale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    target_value = 60
    scale_in_cooldown = 10
    scale_out_cooldown = 5

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
  # depends_on = [aws_appautoscaling_target.ecs_target]
}


##########################


# resource "aws_iam_role" "ecs-autoscale-role" {
#   name = "ba-ecs-scale-${var.cluster_name}-${var.service_name}"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "application-autoscaling.amazonaws.com"
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF

# }

# resource "aws_iam_role_policy_attachment" "ecs_autoscale" {
#   role = aws_iam_role.ecs-autoscale-role.id
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
# }

# resource "aws_iam_role_policy_attachment" "ecs_cloudwatch" {
#   role = aws_iam_role.ecs-autoscale-role.id
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
# }

# Need to change deregisteration time of the ELB to enable faster draining operation
# https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_TargetGroupAttribute.html