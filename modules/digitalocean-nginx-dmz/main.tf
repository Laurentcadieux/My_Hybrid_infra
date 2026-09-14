terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "size" {
  type    = string
  default = "s-1vcpu-1gb"
}

variable "vpc_uuid" {
  type = string
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "vpn_preshared_key" {
  type      = string
  sensitive = true
}

variable "vpn_ip" {
  type    = string
  default = "10.99.0.1"
}

variable "pm_vpn_ip" {
  type    = string
  default = "10.99.0.2"
}

variable "vpn_subnet" {
  type    = string
  default = "10.99.0.0/24"
}

variable "backend_hosts" {
  type        = list(string)
  description = "Backend web VM IPs (Proxmox) to proxy to over VPN"
}

variable "tags" {
  type    = list(string)
  default = []
}

# Upload SSH key
resource "digitalocean_ssh_key" "this" {
  name       = var.name
  public_key = var.ssh_public_key
}

# Nginx DMZ droplet — minimal, reverse proxy only
resource "digitalocean_droplet" "nginx" {
  name       = var.name
  region     = var.region
  size       = var.size
  image      = "debian-12-x64"
  vpc_uuid   = var.vpc_uuid
  ssh_keys   = [digitalocean_ssh_key.this.id]
  tags       = var.tags
  monitoring = true
  backups    = false

  # Cloud-init: install Nginx + WireGuard VPN client to Proxmox
  user_data = <<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - nginx
      - wireguard
      - wireguard-tools
    write_files:
      - path: /etc/wireguard/wg0.conf
        permissions: '0600'
        content: |
          [Interface]
          PrivateKey = ${var.vpn_ip == "" ? "" : "AUTO"}
          Address = ${var.vpn_ip}/24
          [Peer]
          PublicKey = PM_PUBKEY_PLACEHOLDER
          PresharedKey = ${var.vpn_preshared_key}
          AllowedIPs = 10.10.0.0/16, ${var.vpn_subnet}
          Endpoint = PM_PUBLIC_IP:51820
          PersistentKeepalive = 25
      - path: /etc/nginx/sites-available/proxy.conf
        content: |
          upstream backend_web {
            %{~ for host in var.backend_hosts ~}
            server ${host}:80;
            %{~ endfor ~}
          }
          server {
            listen 80 default_server;
            location / {
              proxy_pass http://backend_web;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            }
            location /health {
              access_log off;
              return 200 "ok";
              add_header Content-Type text/plain;
            }
          }
    runcmd:
      - systemctl enable wg-quick@wg0
      - systemctl start wg-quick@wg0
      - ln -sf /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/proxy.conf
      - rm -f /etc/nginx/sites-enabled/default
      - systemctl restart nginx
  CLOUDINIT
}

output "public_ip" {
  value = digitalocean_droplet.nginx.ipv4_address
}

output "private_ip" {
  value = digitalocean_droplet.nginx.ipv4_address_private
}

output "vpn_ip" {
  value = var.vpn_ip
}

output "ssh_key_id" {
  value = digitalocean_ssh_key.this.id
}
