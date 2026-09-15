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
  type = string
}
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "site_domain" {
  type = string
}
variable "wg_private_key" {
  type      = string
  sensitive = true
}
variable "wg_peer_public" {
  type      = string
  sensitive = true
}
variable "vpn_preshared_key" {
  type      = string
  sensitive = true
}
variable "vpn_ip" {
  type = string
}
variable "peer_vpn_ip" {
  type = string
}
variable "vpn_subnet" {
  type = string
}
variable "backend_host" {
  type = string
}
variable "backend_port" {
  type = number
}
variable "tags" {
  type    = list(string)
  default = []
}

resource "digitalocean_ssh_key" "this" {
  name       = var.name
  public_key = var.ssh_public_key
}

# Firewall: only 443 (and 22 for admin) inbound
resource "digitalocean_firewall" "this" {
  name = "${var.name}-fw"

  droplet_ids = [digitalocean_droplet.nginx.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # WireGuard UDP inbound
  inbound_rule {
    protocol         = "udp"
    port_range       = "51820"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Nginx DMZ droplet — SSL termination + reverse proxy + WireGuard
resource "digitalocean_droplet" "nginx" {
  name       = var.name
  region     = var.region
  size       = var.size
  image      = "debian-13-x64"
  ssh_keys   = [digitalocean_ssh_key.this.id]
  tags       = var.tags
  monitoring = true
  user_data  = <<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - nginx
      - wireguard
      - wireguard-tools
      - certbot
      - python3-certbot-nginx
    write_files:
      - path: /etc/wireguard/wg0.conf
        permissions: '0600'
        content: |
          [Interface]
          PrivateKey = ${var.wg_private_key}
          Address = ${var.vpn_ip}/24
          [Peer]
          PublicKey = ${var.wg_peer_public}
          PresharedKey = ${var.vpn_preshared_key}
          AllowedIPs = ${var.peer_vpn_ip}/32
          PersistentKeepalive = 25
      - path: /etc/nginx/sites-available/proxy.conf
        content: |
          server {
            listen 80;
            server_name ${var.site_domain} www.${var.site_domain};
            location / { return 301 https://$host$request_uri; }
          }
          server {
            listen 443 ssl;
            server_name ${var.site_domain} www.${var.site_domain};
            # Certs will be provisioned by certbot
            ssl_certificate /etc/letsencrypt/live/${var.site_domain}/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/${var.site_domain}/privkey.pem;
            location / {
              proxy_pass http://${var.backend_host}:${var.backend_port};
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            }
          }
    runcmd:
      - systemctl enable wg-quick@wg0
      - systemctl start wg-quick@wg0
      - ln -sf /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/proxy.conf
      - rm -f /etc/nginx/sites-enabled/default
      - nginx -t && systemctl restart nginx
      - echo "Run: certbot --nginx -d ${var.site_domain} -d www.${var.site_domain} after DNS is configured"
  CLOUDINIT
}

output "public_ip" {
  value = digitalocean_droplet.nginx.ipv4_address
}

output "vpn_ip" {
  value = var.vpn_ip
}
