# ─── DigitalOcean Edge (Nginx + WireGuard + SSL) ──────────────
module "do_edge" {
  source = "./modules/digitalocean-edge"

  name           = "${var.project_name}-${var.environment}-nginx"
  region         = var.region
  size           = var.do_droplet_size
  ssh_public_key = var.ssh_public_key
  site_domain    = var.site_domain

  # WireGuard — peer is the VPN VM, not the Proxmox host
  wg_private_key    = var.do_wg_private_key
  wg_peer_public    = var.pm_wg_public_key
  vpn_preshared_key = var.vpn_preshared_key
  vpn_ip            = var.do_vpn_ip
  peer_vpn_ip       = var.pm_vpn_ip
  vpn_subnet        = var.vpn_subnet

  # Backend: web-CV VM over VPN (through VPN gateway)
  backend_host = var.pm_vpn_ip
  backend_port = 80

  tags = [var.project_name, var.environment, "dmz", "nginx"]
}

# ─── Proxmox: VPN Gateway VM (WireGuard endpoint) ────────────
module "vpn_gw" {
  source = "./modules/proxmox-vpn-gw"

  name        = "${var.project_name}-${var.environment}-vpn-gw"
  node_name   = var.pm_node_name
  template_id = var.pm_vm_template_id
  bridge      = var.pm_bridge_name
  memory      = var.pm_vpn_gw_memory
  cores       = var.pm_vpn_gw_cores
  disk_size   = var.pm_vpn_gw_disk
  ssh_keys    = [var.ssh_public_key]

  # WireGuard config
  wg_private_key    = var.pm_wg_private_key
  do_wg_public_key  = var.do_wg_public_key
  vpn_preshared_key = var.vpn_preshared_key
  pm_vpn_ip         = var.pm_vpn_ip
  do_vpn_ip         = var.do_vpn_ip
  vpn_subnet        = var.vpn_subnet
}

# ─── Proxmox: web-CV VM ──────────────────────────────────────
module "web_cv" {
  source = "./modules/proxmox-web-cv"

  name        = "${var.project_name}-${var.environment}-web-cv"
  node_name   = var.pm_node_name
  template_id = var.pm_vm_template_id
  bridge      = var.pm_bridge_name
  memory      = var.pm_web_cv_memory
  cores       = var.pm_web_cv_cores
  disk_size   = var.pm_web_cv_disk
  ssh_keys    = [var.ssh_public_key]
  site_repo   = var.site_repo_url
  site_domain = var.site_domain

  # WireGuard config (for reference, VPN runs in vpn-gw VM)
  pm_wg_private_key = var.pm_wg_private_key
  do_wg_public_key  = var.do_wg_public_key
  vpn_preshared_key = var.vpn_preshared_key
  pm_vpn_ip         = var.pm_vpn_ip
  do_vpn_ip         = var.do_vpn_ip
  vpn_subnet        = var.vpn_subnet
}
