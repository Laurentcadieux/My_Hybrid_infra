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
  description = "Load balancer name"
}

variable "region" {
  type        = string
  description = "DigitalOcean region"
}

variable "vpc_uuid" {
  type        = string
  description = "VPC UUID"
}

variable "droplet_ids" {
  type        = list(string)
  description = "IDs of droplets to load balance"
}

variable "droplet_count" {
  type        = number
  description = "Number of droplets"
}

variable "port" {
  type        = number
  description = "Frontend port"
  default     = 80
}

variable "target_port" {
  type        = number
  description = "Backend port"
  default     = 80
}

variable "algorithm" {
  type        = string
  description = "Load balancing algorithm"
  default     = "round_robin"
}

variable "health_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}

variable "enable_ssl" {
  type        = bool
  description = "Enable SSL termination"
  default     = false
}

resource "digitalocean_loadbalancer" "this" {
  name       = var.name
  region     = var.region
  vpc_uuid    = var.vpc_uuid
  algorithm   = var.algorithm

  forwarding_entry {
    entry_port     = var.enable_ssl ? 443 : var.port
    entry_protocol = var.enable_ssl ? "https" : "http"
    target_port    = var.target_port
    target_protocol = "http"
  }

  healthcheck {
    port                     = var.target_port
    protocol                 = "http"
    path                     = var.health_path
    check_interval_seconds   = 10
    healthy_threshold        = 5
    unhealthy_threshold      = 3
    timeout                  = 5
  }

  dynamic "droplet_ids" {
    for_each = toset(var.droplet_ids)
    content {
      droplet_ids = droplet_ids.value
    }
  }
}

output "ip" {
  value = digitalocean_loadbalancer.this.ip
}

output "id" {
  value = digitalocean_loadbalancer.this.id
}
