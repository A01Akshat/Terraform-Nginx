output "web_app_url" {
  description = "Public URL of the Node.js app behind Nginx"
  value       = "http://${aws_instance.node_nginx_app.public_ip}"
}

# ami-0360c520857e3138f