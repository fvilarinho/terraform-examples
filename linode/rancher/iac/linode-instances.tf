# Local variables definition.
locals {
  settings = jsondecode(chomp(file(pathexpand(var.settingsFilename))))
}

# Definition of the VM.
resource "linode_instance" "vm" {
  label     = local.settings.label
  tags      = local.settings.tags
  type      = local.settings.type
  region    = local.settings.region
  image     = local.settings.image
  root_pass = local.settings.defaultPassword

  provisioner "remote-exec" {
    connection {
      host     = self.ip_address
      user     = "root"
      password = local.settings.defaultPassword
    }

    inline = [
      "apt update",
      "apt -y upgrade",
      "curl https://get.docker.com | sh -",
      "systemctl enable docker",
      "systemctl start docker",
      "docker run -d --name rancher --restart=unless-stopped --privileged -p 80:80 -p 443:443 rancher/rancher:latest"
    ]
  }
}