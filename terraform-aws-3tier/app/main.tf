data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.network_state_bucket
    key    = var.network_state_key
    region = var.region
  }
}

# ALB
resource "aws_lb" "alb" {
  name               = "tf-app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids
  security_groups    = [data.terraform_remote_state.network.outputs.alb_sg_id]
  tags               = { Name = "tf-app-alb" }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "tf-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# IAM role for instance (if needed for SSM)
resource "aws_iam_role" "ec2" {
  name               = "tf-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "app" {
  name_prefix   = "tf-app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  network_interfaces {
    security_groups             = [data.terraform_remote_state.network.outputs.app_sg_id]
    associate_public_ip_address = false
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              # simple sample app that listens on 8080
              cat <<'APP' > /home/ec2-user/app.py
              from http.server import BaseHTTPRequestHandler, HTTPServer
              class H(BaseHTTPRequestHandler):
                  def do_GET(self):
                      self.send_response(200)
                      self.send_header('Content-type','text/plain')
                      self.end_headers()
                      self.wfile.write(b"Hello from app")
              HTTPServer(('0.0.0.0',8080), H).serve_forever()
              APP
              python3 /home/ec2-user/app.py &
              EOF
  )
}

data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "tf-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_autoscaling_group" "app" {
  name                = "tf-app-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = data.terraform_remote_state.network.outputs.app_subnet_ids
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]
  health_check_type = "ELB"
  force_delete      = true

  tag {
    key                 = "Name"
    value               = "tf-app-instance"
    propagate_at_launch = true
  }
}

# Attach role/profile outputs
output "alb_dns" { value = aws_lb.alb.dns_name }