# My_Hybrid_infra

Hybrid infrastructure hosting **[laurentcadieux.online](https://laurentcadieux.online)** — a DigitalOcean Nginx edge (SSL termination) connected via WireGuard VPN to a Proxmox on-prem web server.

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │            DigitalOcean (NYC1)               │
                    │                                             │
   Internet ──────▶ │   ┌──────────────────────┐                   │
   DNS → DO IP      │   │  Nginx DMZ Droplet   │                   │
   :443 (SSL)       │   │  s-1vcpu-1gb         │                   │
   :80 → 301 HTTPS  │   │  Let's Encrypt SSL   │                   │
                    │   │  WireGuard server     │                   │
                    │   └──────────┬───────────┘                   │
                    │              │ wg0: 10.99.0.1                  │
                    └──────────────┼───────────────────────────────┘
                                   │ WireGuard VPN (10.99.0.0/24)
                                   │ DO listens, Proxmox connects outbound
                                   │
                    ┌──────────────┼───────────────────────────────┐
                    │  Proxmox VE — hyper101 (On-Prem, Private)    │
                    │              │                               │
                    │  ┌───────────┴──────────┐                    │
                    │  │  VPN Gateway VM (106) │                    │
                    │  │  WireGuard client     │                    │
                    │  │  wg0: 10.99.0.2       │                    │
                    │  │  IP forwarding + NAT   │                    │
                    │  └───────────┬──────────┘                    │
                    │              │ vmbr0                          │
                    │  ┌───────────┴──────────┐                    │
                    │  │  web-CV VM (105)      │                    │
                    │  │  Nginx (React/Vite)   │                    │
                    │  │  Java Voice GW :8088  │                    │
                    │  │  192.168.0.105        │                    │
                    │  └──────────────────────┘                    │
                    └─────────────────────────────────────────────┘
```

## Design

- **DigitalOcean = light edge**: single Nginx reverse proxy, SSL termination, WireGuard server. No app logic in the cloud.
- **Proxmox = all workloads**: VPN gateway VM routes tunnel traffic to web-CV VM serving the website.
- **WireGuard**: DO is the server (listens on :51820). Proxmox VM connects outbound — no public Proxmox endpoint needed.
- **No database**: static React/Vite site + Java voice gateway.
- **No third-party accounts**: pure WireGuard, no Tailscale/Cloudflare.

## Components

| Component | Location | IP | Spec |
|-----------|----------|----|------|
| Nginx edge + SSL | DigitalOcean NYC1 | 192.241.155.248 (public) | s-1vcpu-1gb, Debian 13 |
| WireGuard server | DO droplet | 10.99.0.1 | Port 51820/UDP |
| VPN gateway VM | Proxmox hyper101 | 192.168.0.106 | 1 vCPU, 1GB, 32GB |
| WireGuard client | VPN gateway VM | 10.99.0.2 | Outbound to DO |
| web-CV VM | Proxmox hyper101 | 192.168.0.105 (DHCP) | 2 vCPU, 2GB, 32GB |
| Website | web-CV VM | localhost:80 | React 19 + Vite 6 |
| Voice gateway | web-CV VM | localhost:8088 | Java 17 |
| SSL cert | DO droplet | — | Let's Encrypt, auto-renew |
| Terraform state | Azure Storage | — | rg-terraform-state / hermesterraformstate |

## Traffic Flow

```
Visitor → https://laurentcadieux.online
  → DNS resolves to 192.241.155.248 (DO droplet)
  → Nginx terminates SSL (Let's Encrypt)
  → proxy_pass http://192.168.0.105:80 (over WireGuard tunnel)
  → VPN gateway VM (10.99.0.2) routes to vmbr0
  → web-CV VM Nginx serves React/Vite build
  → Response flows back through tunnel to visitor
```

## Prerequisites

### 1. SSH Key Pair
```bash
ls keys/
# hybrid-infra-admin      (private — gitignored)
# hybrid-infra-admin.pub  (public — in dev.tfvars)
```

### 2. Credentials (all in `.env`, gitignored)
- `DO_TOKEN` — DigitalOcean Personal Access Token
- `PM_API_TOKEN` — Proxmox API token (`root@pam!terraform=secret`)
- `PM_ENDPOINT` — Proxmox API URL
- `ARM_*` — Azure Service Principal for state backend

### 3. Secrets (in `environments/dev/secrets.tfvars`, gitignored)
- WireGuard private/public keys (DO + Proxmox sides)
- WireGuard preshared key

### 4. Proxmox Template
- VM ID 104: Ubuntu 24.04 with cloud-init
- Snippets content type enabled on `local` storage

## Usage

```bash
# Load credentials
set -a && source .env && set +a

# Initialize
terraform init

# Plan (uses 3 tfvars files: config + secrets + credentials)
terraform plan \
  -var-file="environments/dev/dev.tfvars" \
  -var-file="environments/dev/secrets.tfvars" \
  -var-file="environments/dev/credentials.tfvars"

# Apply
terraform apply \
  -var-file="environments/dev/dev.tfvars" \
  -var-file="environments/dev/secrets.tfvars" \
  -var-file="environments/dev/credentials.tfvars"

# Destroy (tears down everything)
terraform destroy \
  -var-file="environments/dev/dev.tfvars" \
  -var-file="environments/dev/secrets.tfvars" \
  -var-file="environments/dev/credentials.tfvars"
```

## Post-Apply Manual Steps

After `terraform apply`, the following are configured manually (not yet automated):

1. **WireGuard on VPN VM** — install and configure (see `modules/proxmox-vpn-gw/`)
2. **WireGuard on DO droplet** — start the service (`systemctl start wg-quick@wg0`)
3. **Website on web-CV VM** — install Nginx, Node.js, Java, clone repo, build
4. **SSL certificate** — run certbot on DO droplet
5. **Nginx proxy config** — point to web-CV VM IP through VPN

## File Structure

```
My_Hybrid_infra/
├── main.tf                          # Providers + Azure backend
├── modules.tf                       # Module wiring (DO edge + VPN VM + web-CV VM)
├── variables.tf                     # All input variables
├── outputs.tf                       # Outputs (IPs, VM IDs)
├── architecture-diagram.html        # Visual architecture diagram
├── environments/dev/
│   ├── dev.tfvars                   # Dev config (committed — no secrets)
│   ├── secrets.tfvars               # WireGuard keys (gitignored)
│   └── credentials.tfvars           # API tokens (gitignored)
├── modules/
│   ├── digitalocean-edge/           # Nginx + WireGuard + firewall + SSL-ready
│   ├── proxmox-vpn-gw/             # VPN gateway VM (WireGuard client)
│   └── proxmox-web-cv/             # Web server VM (Nginx + site)
├── keys/                            # SSH keys (gitignored)
├── .env                             # Credentials (gitignored)
├── .gitignore
└── README.md
```

## Security

### What's Protected
- ✅ No secrets in git (`.env`, `secrets.tfvars`, `credentials.tfvars`, `keys/` all gitignored)
- ✅ Proxmox not exposed to internet (private network, outbound only)
- ✅ WireGuard encrypted tunnel (preshared key + Curve25519)
- ✅ SSL/TLS via Let's Encrypt (auto-renewing)
- ✅ HTTP → HTTPS redirect
- ✅ Terraform state in Azure with locking
- ✅ DO firewall: only ports 80, 443, 22, 51820/UDP inbound

### Known Issues (TODO)
- ⚠️ SSH port 22 open to world on DO droplet — restrict to known IPs
- ⚠️ PasswordAuthentication enabled on web-CV VM — disable, key-only
- ⚠️ No UFW on Proxmox VMs — enable and restrict
- ⚠️ No security headers in Nginx (HSTS, X-Frame-Options, etc.)
- ⚠️ Java voice gateway not started on web-CV VM
- ⚠️ Credentials were shared in chat history — rotate all secrets

### Recommended Hardening
1. Restrict SSH to known source IPs
2. Disable password auth on all VMs (`PasswordAuthentication no`)
3. Enable UFW on Proxmox VMs (allow only 80/22 from VPN VM/local)
4. Add Nginx security headers
5. Rotate all exposed credentials (DO token, Proxmox token, Azure SP, WireGuard keys)
6. Set up log monitoring / fail2ban on DO droplet

## Multi-Site Expansion

The Nginx edge can host multiple sites. To add a new site:

1. Create a new Proxmox VM (add a module in `modules.tf`)
2. Add a new Nginx server block on the DO droplet
3. Point the new domain's DNS to `192.241.155.248`
4. Run certbot for the new domain

Each site proxies through the same WireGuard tunnel to its respective Proxmox VM.
