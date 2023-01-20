provider "aws" {
    region = "us-east-2"
}

# resource "aws_instance" "test" {
#     ami     = "ami-0283a57753b18025b"
#     instance_type =  "t2.micro"
#     vpc_security_group_ids = [aws_security_group.instance.id]

#     user_data = <<-EOF
#               #!/bin/bash
#               echo "Hello, World" > index.html
#               nohup busybox httpd -f -p ${var.server_port} &
#               EOF

#     tags = {
#         Name = "terraform-test"
#     }
# }

# ASG

locals {
  http_port     = 80
  any_port      = 0
  any_porotocol = -1
  tcp_protocol  = "tcp"
  all_ips       = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "test" {
    image_id         = "ami-0283a57753b18025b"
    instance_type    =  var.instance_type
    security_groups  = [aws_security_group.instance.id]
    user_data        = data.template_file.user_data.rendered

    # user_data = <<-EOF
    #           #!/bin/bash
    #           echo "Hello, World" >> index.html
    #           echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
    #           echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
    #           nohup busybox httpd -f -p ${var.server_port} &
    #           EOF

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-${var.cluster_name}"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = local.tcp_protocol
        cidr_blocks = local.all_ips
    }
}



resource "aws_autoscaling_group" "test" {
    launch_configuration = aws_launch_configuration.test.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    target_group_arns = [aws_lb_target_group.test.arn]
    health_check_type = "ELB"

    min_size = var.min_size
    max_size = var.max_size

    tag {
        key = "Name"
        value = var.cluster_name
        propagate_at_launch = true
    }
    dynamic "tag" {
        for_each = var.custom_tags
    
        content {
            key                 = tag.key
            value               = tag.value
            propagate_at_launch = true
        } 
    }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    count = var.enable_autoscaling? 1 : 0

    scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
    min_size = 2
    max_size = 10
    desired_capacity = 10
    recurrence = "0 9 * * *"
    autoscaling_group_name = aws_autoscaling_group.test.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = var.enable_autoscaling? 1 : 0

    scheduled_action_name = "${var.cluster_name}-scale_in_at_night"
    min_size = 2
    max_size = 10
    desired_capacity = 2
    recurrence = "0 17 * * *"
    autoscaling_group_name = aws_autoscaling_group.test.name
}



data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
  
}

# output "public_ip" {
#     value       = aws_instance.test.public_ip
#     description = "The public IP address of the web server"
  
# 

resource "aws_lb" "test" {
    name = "terraform-asg-${var.cluster_name}"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id ]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.test.arn
    port              = local.http_port
    protocol          = "HTTP"  

    default_action {
        type = "fixed-response"

        fixed_response {
          content_type = "text/plain"
          message_body = "404: page not found:"
          status_code  = 404
        }
    }
}

# resource "aws_security_group" "alb" {
#     name = "${var.cluster_name}-alb"

#     ingress {
#         from_port = 80
#         to_port = 80
#         protocol = "tcp"
#         cidr_blocks = [ "0.0.0.0/0" ]
#     }

#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = [ "0.0.0.0/0" ]
#     }
  
# }

resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"  
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type              = "ingress"
    security_group_id = aws_security_group.alb.id

    from_port         =  local.http_port
    to_port           =  local.http_port
    protocol          =  local.tcp_protocol
    cidr_blocks =  local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
    type              = "egress"
    security_group_id = aws_security_group.alb.id

    from_port         =  local.any_port
    to_port           =  local.any_port
    protocol          =  local.any_porotocol
    cidr_blocks =  local.all_ips
  
}


resource "aws_lb_target_group" "test" {
    name            = "terraform-asg-${var.cluster_name}"
    port            = var.server_port
    protocol        = "HTTP"
    vpc_id          = data.aws_vpc.default.id

    health_check {
      path          = "/"
      protocol      = "HTTP"
      matcher       = "200"
      interval      = 15
      timeout       = 3
      healthy_threshold = 2
      unhealthy_threshold = 2 
    }
}


resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.test.arn
    }
 
}

data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket = var.db_remote_state_bucket
        key    = var.db_remote_state_key
        region = "us-east-2"
    }
  
}

data "template_file" "user_data" {
    template = file("${path.module}/user-data.sh")

    vars = {
        server_port = var.server_port
        db_address  = data.terraform_remote_state.db.outputs.address
        db_port     = data.terraform_remote_state.db.outputs.port
    }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilizaion" {
    alarm_name = "${var.cluster_name}-high-cpu-utilizion"
    namespace = "AWS/EC2"
    metric_name = "CPUUtilizaion"

    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.test.name
    }

    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    period              = 300
    statistic           = "Average"
    threshold           = 90
    unit                = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
    alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
    namespace = "AWS/EC2"
    metric_name = "CPUCreditBalance"

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.test.name
    }
}