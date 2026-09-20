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

# Multi-site config: map of domain → backend
variable "sites" {
  type = map(object({
    domain       = string
    backend_ip   = string
    backend_port = number
    ssl          = bool
  }))
  description = "Map of site names to their proxy config. Adding a site = adding an entry here."
}

variable "tags" {
  type    = list(string)
  default = []
}

resource "digitalocean_ssh_key" "this" {
  name       = var.name
  public_key = var.ssh_public_key
}

# Firewall: 80 (ACME + redirect), 443 (HTTPS), 22 (SSH), 51820/UDP (WireGuard)
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

  inbound_rule {
    protocol         = "udp"
    port_range       = "51820"
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
}

# Generate Nginx config from the sites map — one server block per site
locals {
  nginx_config = <<-EOT
    %{~ for name, site in var.sites ~}
    # Site: ${name}
    server {
        listen 80;
        server_name ${site.domain} www.${site.domain};
        location /.well-known/acme-challenge/ { root /var/www/html; }
        location / { return 301 https://$host$request_uri; }
    }
    server {
        listen 443 ssl;
        server_name ${site.domain} www.${site.domain};
        ssl_certificate /etc/letsencrypt/live/${site.domain}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${site.domain}/privkey.pem;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        location / {
            proxy_pass http://${site.backend_ip}:${site.backend_port};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 10s;
            proxy_read_timeout 30s;
        }
    }
    %{~ endfor ~}
  EOT

  certbot_command = join(" && ", [
    for name, site in var.sites : "certbot certonly --nginx -d ${site.domain} -d www.${site.domain} --non-interactive --agree-tos --email admin@${site.domain} || true"
  ])
}

# Nginx DMZ droplet — SSL + multi-site reverse proxy + WireGuard
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
          ListenPort = 51820
          [Peer]
          PublicKey = ${var.wg_peer_public}
          PresharedKey = ${var.vpn_preshared_key}
          AllowedIPs = ${var.peer_vpn_ip}/32, 192.168.0.0/24
      - path: /etc/nginx/sites-available/proxy.conf
        content: |
          ${local.nginx_config}
    runcmd:
      - sysctl -w net.ipv4.ip_forward=1
      - systemctl enable wg-quick@wg0
      - systemctl start wg-quick@wg0
      - ln -sf /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/proxy.conf
      - rm -f /etc/nginx/sites-enabled/default
      - nginx -t && systemctl restart nginx
      - echo "WireGuard + Nginx ready. Run certbot for SSL when DNS is configured."
  CLOUDINIT
}

output "public_ip" {
  value = digitalocean_droplet.nginx.ipv4_address
}

output "vpn_ip" {
  value = var.vpn_ip
}
