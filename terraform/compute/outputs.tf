##############################################
# Web Tier Outputs
##############################################

output "web_alb_dns" {
  description = "DNS name of the internet-facing Web ALB"
  value       = aws_lb.web.dns_name
}

output "web_alb_arn" {
  description = "ARN of the Web ALB"
  value       = aws_lb.web.arn
}

output "web_target_group_arn" {
  description = "ARN of the Web Target Group"
  value       = aws_lb_target_group.web.arn
}

##############################################
# App Tier Outputs
##############################################

output "app_alb_dns" {
  description = "DNS name of the internal App ALB"
  value       = aws_lb.app.dns_name
}

output "app_alb_arn" {
  description = "ARN of the App ALB"
  value       = aws_lb.app.arn
}

output "app_target_group_arn" {
  description = "ARN of the App Target Group"
  value       = aws_lb_target_group.app.arn
}

##############################################
# ASG Outputs
##############################################

output "web_asg_name" {
  description = "Name of the Web Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Name of the App Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}
