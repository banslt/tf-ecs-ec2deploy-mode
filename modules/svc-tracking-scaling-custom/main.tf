resource "aws_appautoscaling_policy" "scale" {
  name               = "${var.scale_policy_name_prefix}-scale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    target_value = var.target_value
    scale_in_cooldown = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
    disable_scale_in = var.disable_scale_in
    customized_metric_specification {
      metric_name = var.metric_name #"MemoryUtilization"
      namespace = var.namespace #"AWS/ECS"
      statistic = var.statistic #"Maximum"
      dimensions {
        name  = element(var.dims.*.name,0) 
        value = element(var.dims.*.value,0)
      }
      dimensions {
        name  = element(var.dims.*.name,1) 
        value = element(var.dims.*.value,1)

      }
    }
  }
}
