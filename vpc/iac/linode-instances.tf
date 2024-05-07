# Local variables definition.
locals {
  settings = jsondecode(chomp(file(pathexpand(var.settingsFilename))))
}

resource "linode_vpc" "vpc" {
  for_each = toset(local.settings.vpcs)
  label    = each.key
  region   = local.settings.region
}

resource "linode_vpc_subnet" "subnet" {
  for_each = {for subnet in local.settings.subnets : subnet.id => subnet}
  vpc_id   = linode_vpc.vpc[each.value.vpc].id
  label    = each.key
  ipv4     = each.value.networkMask
}

resource "linode_instance" "vm" {
  for_each        = {for vm in local.settings.vms : vm.id => vm}
  label           = each.key
  tags            = each.value.tags
  type            = each.value.type
  region          = local.settings.region
  image           = each.value.image
  root_pass       = each.value.defaultPassword
  authorized_keys = [ chomp(file(pathexpand(var.sshPublicKeyFilename))) ]

  interface {
    purpose = "public"
    primary = true
  }

  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.subnet[each.value.subnet].id
  }

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

  depends_on = [
    linode_vpc.vpc,
    linode_vpc_subnet.subnet,
    linode_instance.gateway
  ]
}

resource "linode_instance" "gateway" {
  for_each        = {for gateway in local.settings.gateways : gateway.id => gateway}
  label           = each.key
  tags            = each.value.tags
  type            = each.value.type
  region          = local.settings.region
  image           = each.value.image
  root_pass       = each.value.defaultPassword
  authorized_keys = [ chomp(file(pathexpand(var.sshPublicKeyFilename))) ]

  interface {
    purpose = "public"
    primary = true
  }

  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.subnet[each.value.subnet].id
  }

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

  depends_on = [
    linode_vpc.vpc,
    linode_vpc_subnet.subnet
  ]
}

resource "linode_firewall" "vm" {
  label           = "vm-firewall"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  dynamic "inbound" {
    for_each = {for subnet in local.settings.subnets : subnet.id => subnet}

    content {
      label    = "allow-tcp-vm-${inbound.key}"
      ipv4     = [ inbound.value.networkMask ]
      action   = "ACCEPT"
      protocol = "TCP"
    }
  }

  dynamic "inbound" {
    for_each = {for subnet in local.settings.subnets : subnet.id => subnet}

    content {
      label    = "allow-udp-vm-${inbound.key}"
      ipv4     = [ inbound.value.networkMask ]
      action   = "ACCEPT"
      protocol = "UDP"
    }
  }

  dynamic "inbound" {
    for_each = {for subnet in local.settings.subnets : subnet.id => subnet}

    content {
      label    = "allow-icmp-vm-${inbound.key}"
      ipv4     = [ inbound.value.networkMask ]
      action   = "ACCEPT"
      protocol = "ICMP"
    }
  }
}

resource "linode_firewall_device" "vm" {
  for_each    = {for vm in local.settings.vms : vm.id => vm}
  entity_id   = linode_instance.vm[each.key].id
  firewall_id = linode_firewall.vm.id
  depends_on  = [
    linode_instance.vm,
    linode_firewall.vm
  ]
}