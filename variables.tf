###################
# General Variables
###################

variable "project_name" {
  type        = string
  description = "Project name used for naming resources"
  default     = "hybrid-infra"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  type        = string
  description = "DigitalOcean region for cloud resources"
  default     = "nyc1"
}

###################
# SSH Keys
###################

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key for VM access"
  sensitive   = true
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to private SSH key for Proxmox VM provisioning"
  default     = "keys/hybrid-infra-admin"
}

###################
# DigitalOcean
###################

variable "do_token" {
  type        = string
  description = "DigitalOcean Personal Access Token"
  sensitive   = true
}

variable "do_droplet_size" {
  type        = string
  description = "Droplet size for web app servers"
  default     = "s-2vcpu-4gb"
}

variable "do_droplet_count" {
  type        = number
  description = "Number of web app droplets"
  default     = 2
}

variable "do_db_engine" {
  type        = string
  description = "Database engine (pg or mysql)"
  default     = "pg"
}

variable "do_db_size" {
  type        = string
  description = "Managed database size"
  default     = "db-s-1vcpu-1gb"
}

variable "do_db_node_count" {
  type        = number
  description = "Number of database nodes (1 for dev, 2+ for HA)"
  default     = 1
}

###################
# Proxmox (On-Prem)
###################

variable "pm_endpoint" {
  type        = string
  description = "Proxmox API endpoint URL"
  sensitive   = true
}

variable "pm_api_token" {
  type        = string
  description = "Proxmox API token (format: user@pve!tokenid=secret)"
  sensitive   = true
}

variable "pm_insecure" {
  type        = bool
  description = "Skip TLS verification for Proxmox API (use false in production)"
  default     = true
}

variable "pm_node_name" {
  type        = string
  description = "Proxmox node name to deploy VMs on"
  default     = "pve1"
}

variable "pm_vm_template" {
  type        = string
  description = "Proxmox VM template to clone"
  default     = "debian-12-template"
}

variable "pm_vm_count" {
  type        = number
  description = "Number of on-prem VMs"
  default     = 1
}

variable "pm_vm_memory" {
  type        = number
  description = "Memory in MB for on-prem VMs"
  default     = 4096
}

variable "pm_vm_cores" {
  type        = number
  description = "CPU cores for on-prem VMs"
  default     = 2
}

variable "pm_vm_disk_size" {
  type        = number
  description = "Disk size in GB for on-prem VMs"
  default     = 30
}

variable "pm_bridge_name" {
  type        = string
  description = "Proxmox network bridge for VMs"
  default     = "vmbr0"
}
