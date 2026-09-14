###################
# General
###################

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "hybrid-infra"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "region" {
  type        = string
  description = "DigitalOcean region"
  default     = "nyc1"
}

###################
# SSH
###################

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_private_key_path" {
  type    = string
  default = "keys/hybrid-infra-admin"
}

###################
# DigitalOcean (Light Edge / DMZ)
###################

variable "do_token" {
  type      = string
  sensitive = true
}

variable "do_droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}

###################
# VPN (DO ↔ Proxmox)
###################

variable "vpn_preshared_key" {
  type      = string
  sensitive = true
  default   = "CHANGE_ME_GENERATE_A_REAL_KEY"
}

variable "vpn_subnet" {
  type    = string
  default = "10.99.0.0/24"
}

variable "do_vpn_ip" {
  type    = string
  default = "10.99.0.1"
}

variable "pm_vpn_ip" {
  type    = string
  default = "10.99.0.2"
}

###################
# Proxmox (On-Prem — Dual Node HA/DR)
###################

variable "pm_endpoint" {
  type      = string
  sensitive = true
  description = "Primary Proxmox API endpoint (hyper100)"
}

variable "pm_api_token" {
  type      = string
  sensitive = true
  description = "Proxmox API token (format: user@pve!tokenid=secret)"
}

variable "pm_insecure" {
  type  = bool
  default = true
  description = "Skip TLS verification (set false with valid certs)"
}

variable "pm_node_name" {
  type    = string
  default = "hyper100"
  description = "Primary Proxmox node name"
}

variable "pm_node2_name" {
  type    = string
  default = "hyper101"
  description = "Secondary Proxmox node name (DR target)"
}

variable "pm_vm_template" {
  type    = string
  default = "debian-12-template"
}

variable "pm_bridge_name" {
  type    = string
  default = "vmbr0"
}

# Web front-end VMs
variable "pm_web_count" {
  type    = number
  default = 2
}

variable "pm_web_memory" {
  type    = number
  default = 2048
}

variable "pm_web_cores" {
  type    = number
  default = 2
}

variable "pm_web_disk" {
  type    = number
  default = 20
}

# App server VMs
variable "pm_app_count" {
  type    = number
  default = 2
}

variable "pm_app_memory" {
  type    = number
  default = 4096
}

variable "pm_app_cores" {
  type    = number
  default = 4
}

variable "pm_app_disk" {
  type    = number
  default = 40
}

# Database VM
variable "pm_db_memory" {
  type    = number
  default = 8192
}

variable "pm_db_cores" {
  type    = number
  default = 4
}

variable "pm_db_disk" {
  type    = number
  default = 100
}

###################
# Network Segments
###################

variable "pm_web_subnet" {
  type    = string
  default = "10.10.1.0/24"
}

variable "pm_app_subnet" {
  type    = string
  default = "10.10.2.0/24"
}

variable "pm_db_subnet" {
  type    = string
  default = "10.10.3.0/24"
}
