variable "project_name" {
  type    = string
  default = "hybrid-infra"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

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

variable "vm_name" {
  type    = string
  default = "hybrid-infra-dev-web-cv"
}

variable "vm_memory" {
  type    = number
  default = 2048
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_disk" {
  type    = number
  default = 32
}

variable "vm_static_ip" {
  type    = string
  default = "192.168.0.105"
}

variable "vm_gateway" {
  type    = string
  default = "192.168.0.1"
}
