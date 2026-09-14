project_name    = "hybrid-infra"
environment     = "dev"
region          = "nyc1"

# SSH
ssh_public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZkbH2GXoq4hH4PvGbRRcjRe3a/0Gm8AiNM4Ax1cAD5 hybrid-infra-admin"

# DigitalOcean edge (light — Nginx reverse proxy only)
do_droplet_size = "s-1vcpu-1gb"

# VPN (DO ↔ Proxmox) — non-secret config
vpn_subnet      = "10.99.0.0/24"
do_vpn_ip       = "10.99.0.1"
pm_vpn_ip       = "10.99.0.2"

# Proxmox dual-node HA/DR
pm_node_name   = "hyper100"
pm_node2_name  = "hyper101"
pm_vm_template = "debian-12-template"
pm_bridge_name = "vmbr0"

# Web front-end VMs (spread across both nodes)
pm_web_count   = 2
pm_web_memory  = 2048
pm_web_cores   = 2
pm_web_disk    = 20

# App server VMs (spread across both nodes)
pm_app_count   = 2
pm_app_memory  = 4096
pm_app_cores   = 4
pm_app_disk    = 40

# Database VM (primary on hyper100, DR replica on hyper101)
pm_db_memory  = 8192
pm_db_cores   = 4
pm_db_disk    = 100

# Network segments
pm_web_subnet = "10.10.1.0/24"
pm_app_subnet = "10.10.2.0/24"
pm_db_subnet  = "10.10.3.0/24"
