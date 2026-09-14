# ─── DigitalOcean VPC (edge network) ─────────────────────────
module "do_vpc" {
  source      = "./modules/digitalocean-vpc"
  name        = "${var.project_name}-${var.environment}"
  region      = var.region
  ip_range    = "10.0.0.0/24"
  description = "Edge DMZ VPC for ${var.project_name}"
}

# ─── Nginx DMZ Droplet (reverse proxy only, light footprint) ──
module "nginx_dmz" {
  source = "./modules/digitalocean-nginx-dmz"

  name              = "${var.project_name}-${var.environment}-nginx"
  region            = var.region
  size              = var.do_droplet_size
  vpc_uuid          = module.do_vpc.id
  ssh_public_key    = var.ssh_public_key
  vpn_preshared_key = var.vpn_preshared_key
  vpn_ip            = var.do_vpn_ip
  pm_vpn_ip         = var.pm_vpn_ip
  vpn_subnet        = var.vpn_subnet
  # Proxy to Proxmox web VMs across both nodes via VPN
  backend_hosts     = module.proxmox_web.vm_ips
  tags              = [var.project_name, var.environment, "dmz", "nginx"]
}

# ─── Proxmox: Web Front-End VMs (spread across both nodes) ────
module "proxmox_web" {
  source = "./modules/proxmox-web"

  count       = var.pm_web_count
  name_prefix = "${var.project_name}-${var.environment}-web"
  # Alternate between hyper100 and hyper101 for HA
  node_names  = [var.pm_node_name, var.pm_node2_name]
  template    = var.pm_vm_template
  bridge      = var.pm_bridge_name
  memory      = var.pm_web_memory
  cores       = var.pm_web_cores
  disk_size   = var.pm_web_disk
  subnet      = var.pm_web_subnet
  ssh_keys    = [var.ssh_public_key]
  vpn_ip      = var.pm_vpn_ip
  vpn_psk     = var.vpn_preshared_key
  do_vpn_ip   = var.do_vpn_ip
  vpn_subnet  = var.vpn_subnet
}

# ─── Proxmox: App Server VMs (spread across both nodes) ───────
module "proxmox_app" {
  source = "./modules/proxmox-app"

  count       = var.pm_app_count
  name_prefix = "${var.project_name}-${var.environment}-app"
  # Alternate between hyper100 and hyper101 for HA
  node_names  = [var.pm_node_name, var.pm_node2_name]
  template    = var.pm_vm_template
  bridge      = var.pm_bridge_name
  memory      = var.pm_app_memory
  cores       = var.pm_app_cores
  disk_size   = var.pm_app_disk
  subnet      = var.pm_app_subnet
  ssh_keys    = [var.ssh_public_key]
}

# ─── Proxmox: Database VM (primary on hyper100, DR on hyper101) ─
module "proxmox_db" {
  source = "./modules/proxmox-db"

  name        = "${var.project_name}-${var.environment}-db"
  node_name   = var.pm_node_name
  node2_name  = var.pm_node2_name
  template    = var.pm_vm_template
  bridge      = var.pm_bridge_name
  memory      = var.pm_db_memory
  cores       = var.pm_db_cores
  disk_size   = var.pm_db_disk
  subnet      = var.pm_db_subnet
  ssh_keys    = [var.ssh_public_key]
}
