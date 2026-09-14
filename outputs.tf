output "load_balancer_ip" {
  value       = module.do_loadbalancer.ip
  description = "Public IP of the DigitalOcean load balancer"
}

output "database_private_uri" {
  value       = module.do_database.private_uri
  description = "Private connection URI for managed database"
  sensitive   = true
}

output "droplet_ips" {
  value       = module.do_droplet.ipv4_addresses
  description = "Private IPs of web app droplets"
}

output "proxmox_vm_ips" {
  value       = module.proxmox_vm.vm_ips
  description = "IPs of on-prem Proxmox VMs"
}
