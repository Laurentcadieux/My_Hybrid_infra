output "nginx_public_ip" {
  value       = module.nginx_dmz.public_ip
  description = "Public IP of the Nginx DMZ droplet (entry point)"
}

output "nginx_private_ip" {
  value       = module.nginx_dmz.private_ip
  description = "Private IP of Nginx on the VPC"
}

output "nginx_vpn_ip" {
  value       = module.nginx_dmz.vpn_ip
  description = "VPN IP of the Nginx droplet"
}

output "web_vm_ips" {
  value       = module.proxmox_web.vm_ips
  description = "IPs of Proxmox web front-end VMs"
}

output "app_vm_ips" {
  value       = module.proxmox_app.vm_ips
  description = "IPs of Proxmox app server VMs"
}

output "db_vm_ip" {
  value       = module.proxmox_db.vm_ip
  description = "IP of Proxmox database VM"
}

output "vpn_subnet" {
  value       = var.vpn_subnet
  description = "VPN tunnel subnet between DO and Proxmox"
}
