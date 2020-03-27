variable "alarm_name" {
  description = "The Prefix of the alarm name"
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "service_name" {
  description = "Name of the service"
}

variable "scale_policy_name_prefix" {
  description = "Prefix Name for Scale Policies"
}

variable "evaluation_periods" {
  default = "4"
}

variable "period_down" {
  default = "60"
}

variable "period_up" {
  default = "60"
}

variable "threshold_up" {
  default = "55"
}

variable "threshold_down" {
  default = "10"
}

variable "statistic" {
  default = "Maximum"
}

variable "min_capacity" {
  default = "1"
}

variable "max_capacity" {
  default = "4"
}

variable "lowerbound" {
  default = "0"
}

variable "upperbound" {
  default = "0"
}

variable "scale_up_adjustment" {
  default = "1"
}

variable "scale_down_adjustment" {
  default = "-1"
}

variable "datapoints_to_alarm_up" {
  default = "2"
}

variable "datapoints_to_alarm_down" {
  default = "5"
}

variable "metric_name" {
  # "CPUUtilization" "MemoryUtilization"
  default = "CPUUtilization"
}

variable "namespace" {
  default = "AWS/ECS"
}

variable "tg_arn" {
  default = "*"
}

variable "lb_arn" {
  default = "*"
}

variable "ecs-autoscale-role_arn" {
  
}

variable "dims" {

}
