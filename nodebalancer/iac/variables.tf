# Credentials filename.
variable "credentialsFilename" {
  type = string
  default = ".credentials"
}

# Settings filename.
variable "settingsFilename" {
  type = string
  default = "settings.json"
}

variable "sshPublicKeyFilename" {
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "sshPrivateKeyFilename" {
  type = string
  default = "~/.ssh/id_rsa"
}