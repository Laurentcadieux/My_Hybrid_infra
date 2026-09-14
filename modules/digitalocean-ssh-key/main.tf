terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "name" {
  type        = string
  description = "SSH key name in DigitalOcean"
}

variable "public_key" {
  type        = string
  description = "Public SSH key content"
  sensitive   = true
}

resource "digitalocean_ssh_key" "this" {
  name       = var.name
  public_key = var.public_key
}

output "id" {
  value = digitalocean_ssh_key.this.id
}

output "fingerprint" {
  value = digitalocean_ssh_key.this.fingerprint
}
