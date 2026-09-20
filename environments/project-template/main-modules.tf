# ─── Project VM (Proxmox) ────────────────────────────────────
# Uses the generic proxmox-vm module
module "project_vm" {
  source = "../../modules/proxmox-vm"

  name        = var.vm_name
  node_name   = var.pm_node_name
  template_id = var.pm_vm_template_id
  bridge      = var.pm_bridge_name
  memory      = var.vm_memory
  cores       = var.vm_cores
  disk_size   = var.vm_disk
  ssh_keys    = [var.ssh_public_key]
  static_ip   = var.vm_static_ip
  gateway     = var.vm_gateway
  tags        = ["hybrid-infra", var.project_name]
  description = "VM for project ${var.project_name}"
}

output "vm_id" {
  value = module.project_vm.vm_id
}

output "vm_name" {
  value = module.project_vm.vm_name
}

output "vm_ip" {
  value = var.vm_static_ip
}
