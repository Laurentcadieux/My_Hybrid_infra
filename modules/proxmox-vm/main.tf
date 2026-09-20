terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.0"
    }
  }
}

variable "name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "template_id" {
  type = number
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "memory" {
  type    = number
  default = 2048
}

variable "cores" {
  type    = number
  default = 2
}

variable "disk_size" {
  type    = number
  default = 32
}

variable "ssh_keys" {
  type = list(string)
}

variable "static_ip" {
  type    = string
  default = ""
}

variable "gateway" {
  type    = string
  default = ""
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "description" {
  type    = string
  default = "Managed by Terraform"
}

# Generic Proxmox VM — clone from template, cloud-init, static or DHCP
resource "proxmox_virtual_environment_vm" "vm" {
  name            = var.name
  node_name       = var.node_name
  tags            = var.tags
  stop_on_destroy = true
  description     = var.description

  clone {
    vm_id = var.template_id
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.static_ip != "" ? "${var.static_ip}/24" : "dhcp"
        gateway = var.gateway != "" ? var.gateway : null
      }
    }
    user_account {
      keys     = var.ssh_keys
      username = "ubuntu"
    }
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = false
  }
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.vm.name
}
