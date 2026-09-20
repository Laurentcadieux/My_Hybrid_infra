###################
# General
###################

variable "project_name" {
  type    = string
  default = "hybrid-infra"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "nyc1"
}

###################
# SSH
###################

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

###################
# DigitalOcean
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
# WireGuard VPN
###################

variable "vpn_preshared_key" {
  type      = string
  sensitive = true
}

variable "do_wg_private_key" {
  type      = string
  sensitive = true
}

variable "pm_wg_public_key" {
  type      = string
  sensitive = true
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
# Proxmox
###################

variable "pm_endpoint" {
  type      = string
  sensitive = true
}

variable "pm_api_token" {
  type      = string
  sensitive = true
}

variable "pm_insecure" {
  type    = bool
  default = true
}

variable "pm_node_name" {
  type    = string
  default = "hyper101"
}

variable "pm_vm_template_id" {
  type    = number
  default = 104
}

variable "pm_bridge_name" {
  type    = string
  default = "vmbr0"
}

variable "pm_vpn_gw_memory" {
  type    = number
  default = 1024
}

variable "pm_vpn_gw_cores" {
  type    = number
  default = 1
}

variable "pm_vpn_gw_disk" {
  type    = number
  default = 32
}

variable "pm_vpn_gw_static_ip" {
  type    = string
  default = "192.168.0.106"
}

variable "pm_vpn_gw_gateway" {
  type    = string
  default = "192.168.0.1"
}

###################
# Sites (for Nginx proxy config)
###################

variable "site_domain" {
  type    = string
  default = "laurentcadieux.online"
}

variable "backend_host" {
  type    = string
  default = "192.168.0.105"
}

variable "backend_port" {
  type    = number
  default = 80
}
