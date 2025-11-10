output "web_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of the RDS MySQL instance"
  value       = aws_db_instance.mysql.address
}

output "db_password" {
  description = "Generated DB password (keep secret)"
  value       = random_password.db_password.result
  sensitive   = true
}
