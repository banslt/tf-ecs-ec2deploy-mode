resource "aws_iam_role" "ecs-instance-role" {
  name = "ba-ecs-instance-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-instance-policy.json

}

data "aws_iam_policy_document" "ecs-instance-policy" {
   statement {
      actions = ["sts:AssumeRole"]
      principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
      }
   }
}


resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
   role = aws_iam_role.ecs-instance-role.name
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment-lambda-exec" {
   role = aws_iam_role.ecs-instance-role.name
   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}