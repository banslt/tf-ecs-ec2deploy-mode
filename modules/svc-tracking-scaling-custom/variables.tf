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

variable "target_value" {
 description = "Metric target value"
}

variable "scale_in_cooldown" {
  description = "cooldown after between two scale in operations"
  default = 120
}

variable "scale_out_cooldown" {
  description = "cooldown after between two scale out operations"
  default = 60
}

variable "metric_name" {

}

variable "namespace" {
  description = "Namespace of the selected metric"
}

variable "statistic" {
  description = "Applied Statistic to the metric"
  default = "Average"
}

variable "dims" {

}

variable "disable_scale_in" {
 default = false
}
