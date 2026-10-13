#-----------------------------------------------
#Print Resource Details

output "common_securitygroup_id" {
  description = "Security group ID"
  value       = aws_security_group.common.id

}

#Print web-server Private IP

output "web_server_private_IP" {
  description = "Print web -server IP"
  value       = aws_instance.web-server.private_ip

}



#Print app-servers ID

output "Instances_IDs" {
  description = "Print all-server Instance IDs"
  value = [
    aws_instance.web-server.id
  ]

}
