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
  description = "Droplet name prefix"
}

variable "region" {
  type        = string
  description = "DigitalOcean region"
}

variable "size" {
  type        = string
  description = "Droplet size"
  default     = "s-2vcpu-4gb"
}

variable "count" {
  type        = number
  description = "Number of droplets"
  default     = 2
}

variable "vpc_uuid" {
  type        = string
  description = "VPC UUID to attach droplets to"
}

variable "ssh_key_id" {
  type        = any
  description = "SSH key ID to attach to droplets"
}

variable "tags" {
  type        = list(string)
  description = "Tags for droplets"
  default     = []
}

variable "image" {
  type        = string
  description = "Droplet image (e.g., docker-20-04)"
  default     = "docker-20-04"
}

resource "digitalocean_droplet" "web" {
  count  = var.count
  name   = "${var.name}-${count.index + 1}"
  region = var.region
  size   = var.size
  image  = var.image
  vpc_uuid = var.vpc_uuid
  ssh_keys = [var.ssh_key_id]
  tags   = var.tags

  # Enable private networking
  monitoring = true
  backups    = false
}

output "ids" {
  value = digitalocean_droplet.web[*].id
}

output "ipv4_addresses" {
  value = digitalocean_droplet.web[*].ipv4_address_private
}

output "ipv4_public" {
  value = digitalocean_droplet.web[*].ipv4_address
}
