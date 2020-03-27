# ECS SERVICE ROLE
resource "aws_iam_role" "ecs-service-role" {
  name = "ba-ecs-service-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-service-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ecs.amazonaws.com"]
  }
 }
}

# IAM INSTANCE PROFILE
resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ba-ecs-instance-profile"
  path = "/"
  role = aws_iam_role.ecs-instance-role.id
  provisioner "local-exec" {
  command = "sleep 60"
 }
}
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# IAM AUTOSCALE ROLE

resource "aws_iam_role" "ecs-autoscale-role" {
  name = "ba-ecs-scale-${aws_ecs_cluster.cluster.name}-${aws_ecs_service.service.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ecs_autoscale" {
  role = aws_iam_role.ecs-autoscale-role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch" {
  role = aws_iam_role.ecs-autoscale-role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
