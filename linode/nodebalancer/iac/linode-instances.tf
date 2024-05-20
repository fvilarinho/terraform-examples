resource "linode_instance" "vm" {
  for_each        = {for vm in local.settings.vms : vm.id => vm}
  label           = each.key
  tags            = each.value.tags
  type            = each.value.type
  region          = local.settings.region
  image           = each.value.image
  root_pass       = each.value.defaultPassword
  private_ip      = true
  authorized_keys = [ chomp(file(pathexpand(var.sshPublicKeyFilename))) ]

  provisioner "remote-exec" {
    connection {
      host        = self.ip_address
      user        = "root"
      private_key = chomp(file(pathexpand(var.sshPrivateKeyFilename)))
    }

    inline = [
      "hostnamectl set-hostname ${each.key}",
      "apt update",
      "apt -y upgrade",
      "apt -y install net-tools dnsutils"
    ]
  }
}