output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.epam-jenkins.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.epam-jenkins.public_ip
}

output "instance_private_dns" {
  description = "Private DNS address of the EC2 instance"
  value       = aws_instance.epam-jenkins.private_dns
}

output "instance_public_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = aws_instance.epam-jenkins.public_dns
}
