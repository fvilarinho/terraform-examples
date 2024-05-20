# Local variables definition.
locals {
  credentialsFilename = pathexpand(var.credentialsFilename)
}

# Linode provider definition.
provider "linode" {
  config_path = local.credentialsFilename
}