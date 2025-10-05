Automated provisioning of EC2, Node.js, and Nginx with user_data.

Used systemd to ensure the Node.js app starts automatically on boot.

Configured Nginx as reverse proxy to expose the app on port 80 (standard HTTP).

Managed networking via Security Groups (allowing only HTTP & SSH).
