project_name    = "hybrid-infra"
environment     = "dev"
region          = "nyc1"

# SSH — paste your public key or load from file
# Run: cat keys/hybrid-infra-admin.pub
ssh_public_key  = "PASTE_YOUR_PUBLIC_KEY_HERE"

# DigitalOcean droplet config
do_droplet_size = "s-2vcpu-4gb"
do_droplet_count = 2
do_db_engine    = "pg"
do_db_size      = "db-s-1vcpu-1gb"
do_db_node_count = 1

# Proxmox on-prem config
pm_node_name    = "pve1"
pm_vm_template  = "debian-12-template"
pm_vm_count     = 1
pm_vm_memory    = 4096
pm_vm_cores     = 2
pm_vm_disk_size = 30
pm_bridge_name  = "vmbr0"
