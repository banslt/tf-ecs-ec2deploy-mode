# Allow monitoring instance inbound access for influxdb queries and telegraf
resource "aws_security_group_rule" "monitoring_a" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8086
  to_port         = 8086
  protocol        = "tcp"
  source_security_group_id = aws_security_group.alb.id
}
resource "aws_security_group_rule" "monitoring_b" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8186
  to_port         = 8186
  protocol        = "tcp"
  source_security_group_id = aws_security_group.alb.id
}
resource "aws_security_group_rule" "monitoring_c" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8086
  to_port         = 8086
  protocol        = "tcp"
  source_security_group_id = aws_security_group.ecs_ec2_sg.id
}
resource "aws_security_group_rule" "monitoring_d" {
  security_group_id = "sg-0e6590742913d2fca"
  type            = "ingress"
  from_port       = 8186
  to_port         = 8186
  protocol        = "tcp"
  source_security_group_id = aws_security_group.ecs_ec2_sg.id
}

data "aws_instance" "deploy" {
 filter {
    name   = "tag:Name"
    values = ["ba_ecsdeploy"]
  }
}
data "aws_instance" "trafficgen" {
 filter {
    name   = "tag:Name"
    values = ["ba_ecstrafficgen"]
  }
}
data "aws_instance" "monitoring" {
 filter {
    name   = "tag:Name"
    values = ["ba-ecsmonitoring"]
  }
  filter {
    name   = "instance-type"
    values = ["t2.medium"]
  }
}

resource "aws_security_group" "ecs_ec2_sg" {
  name        = "ba-ecs-ec2-grp"
  description = "allow access to all ports"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    security_groups = ["${aws_security_group.alb.id}"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 8086
    to_port     = 8086
    cidr_blocks = ["${data.aws_instance.monitoring.public_ip}/32"] # Allow influxDB queries on monitoring instance
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [ aws_vpc_peering_connection_accepter.master ]
}

resource "aws_security_group" "alb" {
  name        = "ba-ecs-alb-grp"
  description = "allow access to 3100 8086"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 3100
    to_port         = 3100
    cidr_blocks = ["${data.aws_instance.trafficgen.public_ip}/32",
                   "${data.aws_instance.deploy.public_ip}/32"
                  ] # Allow communication with traffic gen on main instance
  }
  
  ingress {
    protocol    = "TCP"
    from_port   = 8086
    to_port     = 8086
    cidr_blocks = ["${data.aws_instance.monitoring.public_ip}/32"] # Allow influxDB queries on monitoring instance
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [ aws_vpc_peering_connection_accepter.master ]
}
