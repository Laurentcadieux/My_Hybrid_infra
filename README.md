# My_Hybrid_infra

Hybrid infrastructure hosting **[laurentcadieux.online](https://laurentcadieux.online)** — a DigitalOcean Nginx edge (SSL termination) connected via WireGuard VPN to a Proxmox on-prem web server.

## Architecture

```
Internet → DO Nginx (SSL :443) → WireGuard → Proxmox VPN VM → vmbr0 → web-CV VM
```

```
                    ┌─────────────────────────────────────────────┐
   Internet ──────▶ │   DigitalOcean NYC1                         │
   DNS → DO IP      │   Nginx DMZ (s-1vcpu-1gb) + WireGuard server  │
   :443 SSL         │   192.241.155.248                            │
   :80 → 301 HTTPS  └──────────────┬──────────────────────────────┘
                                   │ WireGuard (10.99.0.0/24, outbound)
                    ┌──────────────┼──────────────────────────────┐
                    │  Proxmox hyper101 (Private, Outbound Only) │
                    │  ┌───────────┴──────────┐                    │
                    │  │  VPN Gateway VM (106) │                    │
                    │  │  WireGuard client     │                    │
                    │  └───────────┬──────────┘                    │
                    │  ┌───────────┴──────────┐                    │
                    │  │  web-CV VM (105)      │                    │
                    │  │  Nginx + React/Vite   │                    │
                    │  └──────────────────────┘                    │
                    └─────────────────────────────────────────────┘
```

## Multi-State Terraform + Ansible

Infrastructure is split into independent layers:

| Layer | State File | What it manages | When to change |
|-------|-----------|-----------------|----------------|
| Shared | `shared.tfstate` | DO edge + VPN gateway | Adding new sites to Nginx, changing VPN |
| Project CV | `project-cv.tfstate` | web-CV VM (laurentcadieux.online) | Changing VM specs |
| Project AVH | `project-avh.tfstate` | AVH VM (agenticvaluehub.com) | Changing VM specs |
| Ansible | — | Software on VMs | Deploying apps, updates, hardening |

**Terraform** creates infrastructure (VMs, droplets, firewalls).
**Ansible** configures software (Nginx, WireGuard, apps, security).

### Repo Structure

```
My_Hybrid_infra/
├── environments/
│   ├── shared/              # DO edge + VPN gateway (always on)
│   │   ├── main.tf          # Providers + backend (shared.tfstate)
│   │   ├── main-modules.tf  # DO edge + VPN VM modules
│   │   ├── variables.tf
│   │   ├── dev.tfvars        # Config (committed)
│   │   ├── secrets.tfvars    # WireGuard keys (gitignored)
│   │   └── credentials.tfvars # API tokens (gitignored)
│   ├── project-cv/          # laurentcadieux.online (web-CV VM)
│       ├── main.tf          # Providers + backend (project-cv.tfstate)
│       ├── main-modules.tf  # web-CV VM module
│       ├── variables.tf
│       ├── dev.tfvars
│       └── credentials.tfvars
│   └── project-avh/          # agenticvaluehub.com (AVH VM)
│       ├── main.tf          # Providers + backend (project-avh.tfstate)
│       ├── main-modules.tf  # AVH VM module
│       ├── variables.tf
│       ├── dev.tfvars
│       └── credentials.tfvars
├── modules/
│   ├── digitalocean-edge/   # Nginx + WireGuard + firewall (multi-site)
│   └── proxmox-vm/          # Generic reusable VM module
├── playbooks/
│   ├── site.yml             # Full provision (harden + VPN + web + SSL)
│   ├── deploy-site.yml      # Deploy/update website only
│   ├── harden.yml           # Security hardening only
│   └── ssl.yml              # Get/renew SSL certificates
├── roles/
│   ├── common/              # SSH hardening, UFW, fail2ban
│   ├── vpn-gateway/         # WireGuard client + routing
│   └── web-cv/             # Nginx + Node.js + Java + site deploy
├── inventory/
│   ├── hosts.yml            # Host inventory
│   └── group_vars/all.yml   # Shared Ansible vars
├── ansible.cfg
├── architecture-diagram.html
├── keys/                    # SSH keys (gitignored)
├── .env                     # Credentials (gitignored)
└── .env.example
```

## Usage

### 1. Terraform — Create Infrastructure

```bash
# Shared (DO edge + VPN gateway)
cd environments/shared
set -a && source ../../.env && set +a
terraform init
terraform apply -var-file=dev.tfvars -var-file=secrets.tfvars -var-file=credentials.tfvars

# Project CV (web-CV VM)
cd ../project-cv
terraform apply -var-file=dev.tfvars -var-file=credentials.tfvars
```

### 2. Ansible — Configure Software

```bash
# Full provisioning (harden all + VPN + web + SSL)
ansible-playbook playbooks/site.yml -i inventory/hosts.yml

# Or individual tasks:
ansible-playbook playbooks/harden.yml      # Security hardening
ansible-playbook playbooks/deploy-site.yml  # Deploy/update website
ansible-playbook playbooks/ssl.yml          # SSL certificates
```

### 3. Adding a New Project

```bash
# 1. Create new environment
cp -r environments/project-cv environments/project-saas-1
# Edit: change backend key to "project-saas-1.tfstate", update VM name/IP

# 2. Create the VM
cd environments/project-saas-1
terraform init && terraform apply -var-file=dev.tfvars -var-file=credentials.tfvars

# 3. Add site to shared Nginx (one entry in the sites map)
cd ../shared
# Edit main-modules.tf → add entry to the "sites" map:
#   "saas-1" = { domain = "app.myother.com", backend_ip = "192.168.0.107", backend_port = 3000, ssl = true }
terraform apply -var-file=dev.tfvars -var-file=secrets.tfvars -var-file=credentials.tfvars

# 4. Point DNS to 192.241.155.248
# 5. Run certbot for the new domain
ansible-playbook playbooks/ssl.yml -i inventory/hosts.yml -e domains=app.myother.com

# 6. Deploy the app via Ansible (create a role for it)
```

## Multi-Site Nginx

The DO edge module uses a data-driven `sites` map. Adding a site is one entry:

```hcl
sites = {
  "cv" = {
    domain       = "laurentcadieux.online"
    backend_ip   = "192.168.0.105"
    backend_port = 80
    ssl          = true
  }
  "avh" = {
    domain       = "agenticvaluehub.com"
    backend_ip   = "192.168.0.110"
    backend_port = 3000
    ssl          = true
  }
  # New site:
  "saas-1" = {
    domain       = "app.myother.com"
    backend_ip   = "192.168.0.107"
    backend_port = 3000
    ssl          = true
  }
}
```

Nginx config and security headers are generated automatically. No manual Nginx editing.

## Security

### Protected
- ✅ No secrets in git (`.env`, `secrets.tfvars`, `credentials.tfvars`, `keys/`, vault all gitignored)
- ✅ Proxmox not exposed to internet (private, outbound only)
- ✅ WireGuard encrypted tunnel
- ✅ SSL/TLS via Let's Encrypt (auto-renewing)
- ✅ HTTP → HTTPS redirect + security headers (HSTS, X-Frame-Options, etc.)
- ✅ Separate states per project (blast radius containment)
- ✅ Ansible hardening role (SSH key-only, UFW, fail2ban)
- ✅ Terraform state in Azure with locking

### Ansible Security Roles
- **common** — disables password SSH, disables root login, enables UFW + fail2ban
- **vpn-gateway** — WireGuard config, IP forwarding, NAT rules
- **web-cv** — Nginx, Node.js, Java, site deployment

## Prerequisites

- Terraform >= 1.7.0
- Ansible (for post-Terraform provisioning)
- SSH key pair in `keys/`
- `.env` with DO token, Proxmox token, Azure SP credentials
- Proxmox template (VM 104: Ubuntu 24.04 with cloud-init)

## CI/CD (GitHub Actions)

Workflows run automatically on push/PR to main:

| Workflow | Triggers | Action |
|----------|----------|--------|
| `terraform-shared.yml` | Changes in `environments/shared/` or `modules/` | Plan on PR, apply on push to main |
| `terraform-project-cv.yml` | Changes in `environments/project-cv/` | Plan on PR, apply on push to main |
| `terraform-project-avh.yml` | Changes in `environments/project-avh/` | Plan on PR, apply on push to main |
| `deploy-website.yml` | Manual or repository_dispatch | Ansible deploy to web-CV VM |

### Required GitHub Secrets

Set these in https://github.com/Laurentcadieux/My_Hybrid_infra/settings/secrets/actions:

| Secret | Description |
|--------|-------------|
| `DO_TOKEN` | DigitalOcean API token |
| `PM_API_TOKEN` | Proxmox API token |
| `PM_ENDPOINT` | Proxmox API URL |
| `SSH_PUBLIC_KEY` | SSH public key for VMs |
| `DO_WG_PRIVATE_KEY` | DO WireGuard private key |
| `PM_WG_PUBLIC_KEY` | Proxmox WireGuard public key |
| `VPN_PSK` | WireGuard preshared key |
| `ARM_CLIENT_ID` | Azure SP client ID |
| `ARM_CLIENT_SECRET` | Azure SP secret |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure tenant ID |
| `DEPLOY_SSH_KEY` | SSH private key for Ansible deploys |

## Monitoring (Phase 5)

Uptime Kuma runs on the DO edge droplet via Docker, accessible at `status.laurentcadieux.online`:

```bash
# Install monitoring
ansible-playbook playbooks/monitoring.yml -i inventory/hosts.yml

# Then point status.laurentcadieux.online DNS to 192.241.155.248
# Run certbot for the status subdomain
```

Features:
- HTTP/HTTPS uptime monitoring for all sites
- Response time tracking
- Notification via email, Discord, Telegram, etc.
- Status page at `https://status.laurentcadieux.online`
