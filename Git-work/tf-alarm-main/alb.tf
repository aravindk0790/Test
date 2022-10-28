locals {
  ec2_details = { 
    "ADOBE-PROXY-${terraform.workspace}-A" = aws_instance.adobe_zone_a.id,
    "ADOBE-PROXY-${terraform.workspace}-B" = aws_instance.adobe_zone_b.id
  }
}

# Application Load balancer

resource "aws_alb" "bta" {
  for_each           = { for k, v in data.terraform_remote_state.bt-vpc.outputs.public_subnets : k => v.id }
  name               = "beyond-trust-bta-alb-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.bta.id]
  subnets            = each.value
  tags {
    Name = "beyond-trust-bta-${terraform.workspace}"
  }
}

# Target Group

resource "aws_alb_target_group" "bta" {
  name        = "beyond-trust-bta-tg-${terraform.workspace}"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.bt-vpc.outputs.vpc_id
}

# Target group attachment

resource "aws_alb_target_group_attachment" "bta" {
  for_each         = local.ec2_details
  target_group_arn = aws_lb_target_group.bta.arn
  target_id        = each.value
}

# http listener

resource "aws_alb_listener" "bta_http" {
  load_balancer_arn = aws_alb.bta.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# https listener

resource "aws_alb_listener" "bta_https" {
  load_balancer_arn = aws_alb.bta.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.bta.arn
  }
}

# Listener certificate

resource "aws_lb_listener_certificate" "bta" {
  listener_arn    = aws_alb_listener.bta_https.arn
  certificate_arn = aws_acm_certificate.main.arn
}

# Listener Rule

resource "aws_alb_listener_rule" "bta" {
  listener_arn = aws_alb_listener.bta.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.bta.arn
  }
  condition {}
}
