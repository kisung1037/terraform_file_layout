output "alb_dns_name" {
    value = aws_lb.test.dns_name
}

output "asg_name" {
    value = aws_autoscaling_group.test.name
}

output "alb_security_group_id" {
    value = aws_security_group.alb.id  
}