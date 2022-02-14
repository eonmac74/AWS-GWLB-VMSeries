
# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN APPLICATION LOAD BALANCER FOR THE APP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb" "alb" {
  name            = "app-alb-${random_id.deployment_id.hex}"
  subnets         = data.aws_subnet_ids.alb_subnet_ids.ids
  security_groups = [aws_security_group.app-sg.id]
  internal        = false
  tags = {
    Name      = "app-alb-${random_id.deployment_id.hex}"
    yor_trace = "8f6c92ed-1d99-48eb-b8d7-76710cf6d5d4"
  }
}

resource "aws_alb_target_group" "alb-tg" {
  name        = "app-tg-${random_id.deployment_id.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "instance"
  tags = {
    yor_trace = "6027780e-450b-4486-b528-dc1e6c07351f"
  }
}

resource "aws_alb_target_group_attachment" "tg-register" {
  target_group_arn = aws_alb_target_group.alb-tg.arn
  target_id        = aws_instance.app_instance.id
  port             = 80
  depends_on       = [aws_instance.app_instance]
}

resource "aws_alb_listener" "alb-listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-tg.arn
  }
  tags = {
    yor_trace = "50758d8a-cd0a-45e5-bb8c-7af94389fb62"
  }
}
