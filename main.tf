provider "aws" {
  region = "us-east-1"
}

// default VPC is used here
resource "aws_security_group" "node_nginx_sg" {
  name = "node_nginx_sg"
  description = "Security Group"
  
  ingress {
    description = "SSH"    //a protocol used to securely connect to remote servers (like AWS EC2 instance) over the internet
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"     // protocol = "-1" means “all protocols”.The instance can send traffic to any destination on the internet
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_key_pair" "deployer" {
  key_name = "terra-key"
  public_key = file("terra-key.pub")
}


resource "aws_instance" "node_nginx_app" {
  ami = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.node_nginx_sg.id]

   user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Node.js
              curl -sL https://rpm.nodesource.com/setup_16.x | bash -
              yum install -y nodejs git nginx

              # Create Node.js app
              mkdir -p /home/ec2-user/nodeapp
              cd /home/ec2-user/nodeapp

              cat <<EOT > index.js
              const http = require('http');
              const port = 3000;
              const server = http.createServer((req, res) => {
                res.statusCode = 200;
                res.setHeader('Content-Type', 'text/plain');
                res.end('Hello from Terraform Node.js App behind Nginx 🚀');
              });
              server.listen(port, () => {
                console.log('Server running at port', port);
              });
              EOT

              # Create systemd service for Node.js
              cat <<EOT > /etc/systemd/system/nodeapp.service
              [Unit]
              Description=Node.js App
              After=network.target

              [Service]
              ExecStart=/usr/bin/node /home/ec2-user/nodeapp/index.js
              Restart=always
              User=ec2-user
              Environment=PATH=/usr/bin:/usr/local/bin
              WorkingDirectory=/home/ec2-user/nodeapp

              [Install]
              WantedBy=multi-user.target
              EOT

              systemctl daemon-reload
              systemctl enable nodeapp
              systemctl start nodeapp

              # Configure Nginx as reverse proxy
              cat <<EOT > /etc/nginx/conf.d/nodeapp.conf
              server {
                  listen 80;
                  server_name _;

                  location / {
                      proxy_pass http://127.0.0.1:3000;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade \$http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host \$host;
                      proxy_cache_bypass \$http_upgrade;
                  }
              }
              EOT

              systemctl enable nginx
              systemctl restart nginx
              EOF

  tags = {
    Name = "Terraform-NodeApp-Nginx"
  }
}