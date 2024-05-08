# Local variables definition.
locals {
  credentialsFilename = pathexpand(var.credentialsFilename)
}

# Linode provider definition.
provider "linode" {
  config_path = local.credentialsFilename
}

# Local variables definition.
locals {
  settings = jsondecode(chomp(file(pathexpand(var.settingsFilename))))
}