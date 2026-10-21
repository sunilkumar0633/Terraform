resource "terraform_data" "frontend_deployment" {

  # Re-run frontend deployment when either file changes.
  triggers_replace = [
    filesha256("${path.module}/frontend-deploy.sh"),
    filesha256("${path.module}/society.conf")
  ]



  connection {
    type        = "ssh"
    host        = data.aws_instances.backend.public_ips[0]
    user        = "ec2-user"
    private_key = file(var.ssh_key)
    timeout     = "5m"
  }


  # 1. Copy deployment script to EC2
  provisioner "file" {
    source      = "${path.module}/frontend-deploy.sh"
    destination = "/tmp/frontend-deploy.sh"
  }

  # 2. Copy Nginx configuration to EC2
  provisioner "file" {
    source      = "${path.module}/society.conf"
    destination = "/tmp/society.conf"
  }

  # 3. Execute frontend deployment on EC2
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/frontend-deploy.sh",
      "sudo bash /tmp/frontend-deploy.sh",
      "rm -f /tmp/frontend-deploy.sh /tmp/society.conf"
    ]
  }

  # 4. Write a report on the local machine
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "Set-Content -Path '${path.module}/frontend-deployment-report.txt' -Value 'Frontend deployment completed'"
  }
}

data "aws_instances" "backend" {
  filter {
    name   = "tag:Name"
    values = ["society-app-backend"]
  }
}
