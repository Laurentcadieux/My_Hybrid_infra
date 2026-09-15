output "nginx_public_ip" {
  value       = module.do_edge.public_ip
  description = "Public IP — point DNS here"
}

output "nginx_vpn_ip" {
  value       = module.do_edge.vpn_ip
  description = "WireGuard IP of Nginx droplet"
}

output "vpn_gw_vm_id" {
  value       = module.vpn_gw.vm_id
  description = "Proxmox VM ID of VPN gateway"
}

output "vpn_gw_vm_name" {
  value       = module.vpn_gw.vm_name
  description = "Proxmox VM name of VPN gateway"
}

output "web_cv_vm_id" {
  value       = module.web_cv.vm_id
  description = "Proxmox VM ID of web-CV"
}

output "web_cv_vm_name" {
  value       = module.web_cv.vm_name
  description = "Proxmox VM name"
}

output "site_domain" {
  value       = var.site_domain
  description = "Domain to point to nginx_public_ip"
}
