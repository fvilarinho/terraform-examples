# Local variables definition.
locals {
  settings = jsondecode(chomp(file(pathexpand(var.settingsFilename))))
}

# Definition of the swap disk.
resource "linode_instance_disk" "swap" {
  label      = "swap"
  linode_id  = linode_instance.vm.id
  size       = local.settings.swapSize
  filesystem = "swap"
  depends_on = [ linode_instance.vm ]
}

# Definition of the boot disk.
resource "linode_instance_disk" "boot" {
  label      = "boot"
  linode_id  = linode_instance.vm.id
  size       = local.settings.diskSize
  image      = local.settings.image
  root_pass  = local.settings.defaultPassword
  filesystem = "ext4"
  depends_on = [ linode_instance.vm ]
}

# Definition of the instance configuration.
resource "linode_instance_config" "vm" {
  linode_id = linode_instance.vm.id
  label     = "config"

  // boot
  device {
    device_name = "sda"
    disk_id     = linode_instance_disk.boot.id
  }

  // swap
  device {
    device_name = "sdb"
    disk_id     = linode_instance_disk.swap.id
  }

  booted     = true
  depends_on = [
    linode_instance.vm,
    linode_instance_disk.swap,
    linode_instance_disk.boot
  ]
}

# Definition of the VM.
resource "linode_instance" "vm" {
  label     = local.settings.label
  tags      = local.settings.tags
  type      = local.settings.type
  region    = local.settings.region
}