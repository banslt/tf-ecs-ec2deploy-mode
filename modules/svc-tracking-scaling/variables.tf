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

variable "statistic" {
  default = "Maximum"
}

variable "min_capacity" {
  default = "1"
}

variable "max_capacity" {
  default = "4"
}

variable "scale_up_adjustment" {
  default = "1"
}

variable "scale_down_adjustment" {
  default = "-1"
}

variable "ecs_autoscale_role_arn" {
  description = "ARN of the autoscale group"
}
