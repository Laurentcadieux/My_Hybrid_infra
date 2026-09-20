# ─── DigitalOcean Edge (Nginx + WireGuard + SSL + Firewall) ───
module "do_edge" {
  source = "../../modules/digitalocean-edge"

  name           = "${var.project_name}-${var.environment}-nginx"
  region         = var.region
  size           = var.do_droplet_size
  ssh_public_key = var.ssh_public_key

  wg_private_key    = var.do_wg_private_key
  wg_peer_public    = var.pm_wg_public_key
  vpn_preshared_key = var.vpn_preshared_key
  vpn_ip            = var.do_vpn_ip
  peer_vpn_ip       = var.pm_vpn_ip
  vpn_subnet        = var.vpn_subnet

  # Multi-site config — add new sites here
  sites = {
    "cv" = {
      domain       = "laurentcadieux.online"
      backend_ip   = "192.168.0.105"
      backend_port = 80
      ssl          = true
    }
    "avh" = {
      domain       = "agenticvaluehub.com"
      backend_ip   = "192.168.0.105"
      backend_port = 3000
      ssl          = true
    }
    # Add new sites like this:
    # "saas-1" = {
    #   domain       = "app.myother.com"
    #   backend_ip   = "192.168.0.107"
    #   backend_port = 3000
    #   ssl          = true
    # }
  }

  tags = [var.project_name, var.environment, "dmz", "nginx"]
}

# ─── Proxmox: VPN Gateway VM (WireGuard client, outbound) ────
module "vpn_gw" {
  source = "../../modules/proxmox-vm"

  name        = "${var.project_name}-${var.environment}-vpn-gw"
  node_name   = var.pm_node_name
  template_id = var.pm_vm_template_id
  bridge      = var.pm_bridge_name
  memory      = var.pm_vpn_gw_memory
  cores       = var.pm_vpn_gw_cores
  disk_size   = var.pm_vpn_gw_disk
  ssh_keys    = [var.ssh_public_key]
  static_ip   = var.pm_vpn_gw_static_ip
  gateway     = var.pm_vpn_gw_gateway
  tags        = ["hybrid-infra", "vpn-gw"]
  description = "WireGuard VPN gateway — routes DO traffic to internal VMs"
}

output "nginx_public_ip" {
  value = module.do_edge.public_ip
}

output "nginx_vpn_ip" {
  value = module.do_edge.vpn_ip
}

output "vpn_gw_vm_id" {
  value = module.vpn_gw.vm_id
}

output "vpn_gw_vm_name" {
  value = module.vpn_gw.vm_name
}
