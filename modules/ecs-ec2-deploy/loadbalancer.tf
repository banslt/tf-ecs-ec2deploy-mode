# LOAD BALANCER

resource "aws_lb" "loadbalancer" {
  name                = "ba-ecs-ec2-alb-name"
  subnets             = flatten([aws_subnet.public.*.id])  # public subnets
  security_groups     = [aws_security_group.alb.id] 
  depends_on = [
    aws_subnet.public
    ,aws_internet_gateway.gw
  ]
  provisioner "local-exec" {
    command = "echo ${aws_lb.loadbalancer.dns_name} > ../../lb_addr/loadbalancer_address"
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name        = "ba-ecs-ec2-alb-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  deregistration_delay = 10
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.loadbalancer.id
  port              = var.app_port
  protocol          = "HTTP"
  
  default_action {
    target_group_arn = aws_lb_target_group.lb_target_group.id
    type             = "forward"
  }
}
