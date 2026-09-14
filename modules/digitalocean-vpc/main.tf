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
  description = "VPC name"
}

variable "region" {
  type        = string
  description = "DigitalOcean region"
}

variable "ip_range" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "description" {
  type        = string
  description = "VPC description"
  default     = "Managed by Terraform"
}

resource "digitalocean_vpc" "this" {
  name        = var.name
  region      = var.region
  ip_range    = var.ip_range
  description = var.description
}

output "id" {
  value = digitalocean_vpc.this.id
}

output "urn" {
  value = digitalocean_vpc.this.urn
}

output "ip_range" {
  value = digitalocean_vpc.this.ip_range
}
