resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_up_alarm" {
  alarm_name          = "${var.alarm_name}-ECSServiceScaleUpAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period_down
  statistic           = var.statistic
  threshold           = var.threshold_up
  datapoints_to_alarm = var.datapoints_to_alarm_up

  dimensions = {
    element(var.dims.*.name,0) = element(var.dims.*.value,0)
    element(var.dims.*.name,1) = element(var.dims.*.value,1)
  }

  alarm_description = "This metric monitor ecs CPU utilization up"
  alarm_actions     = [aws_appautoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_down_alarm" {
  alarm_name          = "${var.alarm_name}-ECSServiceScaleDownAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.datapoints_to_alarm_down
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period_down
  statistic           = var.statistic
  threshold           = var.threshold_down
  datapoints_to_alarm = var.datapoints_to_alarm_down

  dimensions = {
    element(var.dims.*.name,0) = element(var.dims.*.value,0)
    element(var.dims.*.name,1) = element(var.dims.*.value,1)
  }

  alarm_description = "This metric monitor ecs CPU utilization down"
  alarm_actions     = [aws_appautoscaling_policy.scale_down.arn]
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "${var.scale_policy_name_prefix}-scale-down"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = var.upperbound
      scaling_adjustment          = var.scale_down_adjustment
    }
  }

}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.scale_policy_name_prefix}-scale-up"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = var.lowerbound
      scaling_adjustment          = var.scale_up_adjustment
    }
  }

}
