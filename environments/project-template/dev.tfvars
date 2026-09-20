project_name = "CHANGEME"
environment  = "dev"

# SSH
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZkbH2GXoq4hH4PvGbRRcjRe3a/0Gm8AiNM4Ax1cAD5 hybrid-infra-admin"

# Proxmox
pm_node_name      = "hyper101"
pm_vm_template_id = 104
pm_bridge_name    = "vmbr0"

# VM config — change these
vm_name      = "CHANGEME-vm"
vm_memory    = 2048
vm_cores     = 2
vm_disk      = 32
vm_static_ip = "192.168.0.X"
vm_gateway   = "192.168.0.1"
