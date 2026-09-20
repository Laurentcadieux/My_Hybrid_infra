project_name = "hybrid-infra"
environment  = "dev"
region       = "nyc1"

# SSH
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZkbH2GXoq4hH4PvGbRRcjRe3a/0Gm8AiNM4Ax1cAD5 hybrid-infra-admin"

# DigitalOcean
do_droplet_size = "s-1vcpu-1gb"

# WireGuard
vpn_subnet = "10.99.0.0/24"
do_vpn_ip  = "10.99.0.1"
pm_vpn_ip  = "10.99.0.2"

# Proxmox
pm_node_name      = "hyper101"
pm_vm_template_id = 104
pm_bridge_name    = "vmbr0"
pm_vpn_gw_memory  = 1024
pm_vpn_gw_cores   = 1
pm_vpn_gw_disk    = 32
pm_vpn_gw_static_ip = "192.168.0.106"
pm_vpn_gw_gateway   = "192.168.0.1"

# Nginx proxy — update backend_host when adding new projects
site_domain   = "laurentcadieux.online"
backend_host  = "192.168.0.105"
backend_port  = 80
