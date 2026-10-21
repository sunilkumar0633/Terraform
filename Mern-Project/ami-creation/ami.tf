
resource "terraform_data" "ami_cleanup" {
  connection {
    type        = "ssh"
    host        = data.aws_instances.society_backend.public_ips[0]
    user        = "ec2-user"
    private_key = file(var.ssh_key)
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/ami-cleanup.sh"
    destination = "/tmp/ami-cleanup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/ami-cleanup.sh",
      "sudo bash /tmp/ami-cleanup.sh"
    ]
  }
}


# Find the existing backend EC2 instance
data "aws_instances" "society_backend" {
  filter {
    name   = "tag:Project"
    values = ["SocietyManagement"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Create an AMI from the existing EC2 instance
resource "aws_ami_from_instance" "society_app" {
  name               = "society-management-app-ami"
  source_instance_id = data.aws_instances.society_backend.ids[0]

  depends_on = [terraform_data.ami_cleanup]

  tags = {
    Name        = "society-management-app-ami"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

output "society_ami_id" {
  value = aws_ami_from_instance.society_app.id
}
