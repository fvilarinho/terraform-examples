resource "linode_nodebalancer" "vms" {
  label                = local.settings.nodeBalancer.id
  tags                 = local.settings.nodeBalancer.tags
  client_conn_throttle = local.settings.nodeBalancer.connectionThrottle
  region               = local.settings.region
}

resource "linode_nodebalancer_config" "vms" {
  nodebalancer_id = linode_nodebalancer.vms.id
  protocol        = local.settings.nodeBalancer.healthCheck.protocol
  port            = local.settings.nodeBalancer.healthCheck.port
  check           = "connection"
  check_interval  = local.settings.nodeBalancer.healthCheck.interval
  check_timeout   = local.settings.nodeBalancer.healthCheck.timeout
  check_attempts  = local.settings.nodeBalancer.healthCheck.attempts
  depends_on      = [ linode_nodebalancer.vms ]
}

resource "linode_nodebalancer_node" "vms" {
  for_each        = {for vm in local.settings.vms : vm.id => vm}
  nodebalancer_id = linode_nodebalancer.vms.id
  config_id       = linode_nodebalancer_config.vms.id
  address         = "${linode_instance.vm[each.key].private_ip_address}:${local.settings.nodeBalancer.port}"
  label           = each.key
  weight          = floor(100 / length(local.settings.vms))
  depends_on      = [
    linode_nodebalancer.vms,
    linode_nodebalancer_config.vms,
    linode_instance.vm
  ]
}