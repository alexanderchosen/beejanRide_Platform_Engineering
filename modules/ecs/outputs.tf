output "cluster_name" {
  value = aws_ecs_cluster.create_ecs_cluster.name
}

output "service_name" {
  value = aws_ecs_service.create_ecs_service.name
}

output "asg_name" {
  value = aws_autoscaling_group.create_asg.name
}

output "instance_sg_id" {
  value = aws_security_group.instances.id
}

output "task_role_arn" {
  value = module.task_iam.role_arn
}