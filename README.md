# My_Hybrid_infra

Hybrid infrastructure hosting **[laurentcadieux.online](https://laurentcadieux.online)** — a DigitalOcean Nginx edge (SSL termination) connected via WireGuard VPN to a Proxmox on-prem web server.

## Architecture

```
Internet → DO Nginx (SSL :443) → WireGuard → Proxmox VPN VM → vmbr0 → web-CV VM
```

```
                    ┌─────────────────────────────────────────────┐
                    │            DigitalOcean (NYC1)               │
   Internet ──────▶ │   Nginx DMZ (s-1vcpu-1gb, Debian 13)        │
   DNS → DO IP      │   SSL: Let's Encrypt • WireGuard server     │
   :443 (SSL)       │   192.241.155.248 (public)                   │
   :80 → 301 HTTPS  └──────────────┬──────────────────────────────┘
                                   │ WireGuard VPN (10.99.0.0/24)
                                   │ DO listens, Proxmox connects outbound
                    ┌──────────────┼──────────────────────────────┐
                    │  Proxmox VE — hyper101 (Private)           │
                    │  ┌───────────┴──────────┐                   │
                    │  │  VPN Gateway VM (106) │                   │
                    │  │  WireGuard client     │                   │
                    │  │  10.99.0.2 → vmbr0    │                   │
                    │  └───────────┬──────────┘                   │
                    │  ┌───────────┴──────────┐                   │
                    │  │  web-CV VM (105)      │                   │
                    │  │  Nginx + React/Vite   │                   │
                    │  │  192.168.0.105        │                   │
                    │  └──────────────────────┘                   │
                    └─────────────────────────────────────────────┘
```

## Multi-State Architecture

The infrastructure is split into **independent Terraform states** so projects can be added/removed without affecting each other:

```
environments/
├── shared/          # DO edge + VPN gateway — always on, shared by all projects
│   ├── main.tf             # Providers + Azure backend (shared.tfstate)
│   ├── main-modules.tf     # DO edge + VPN gateway modules
│   ├── variables.tf
│   ├── dev.tfvars           # Config (committed, no secrets)
│   ├── secrets.tfvars       # WireGuard keys (gitignored)
│   └── credentials.tfvars   # API tokens (gitignored)
│
└── project-cv/      # laurentcadieux.online — one project
    ├── main.tf             # Providers + Azure backend (project-cv.tfstate)
    ├── main-modules.tf     # web-CV VM module
    ├── variables.tf
    ├── dev.tfvars           # Config (committed, no secrets)
    └── credentials.tfvars   # API tokens (gitignored)
```

### Adding a New Project

```bash
# 1. Create a new environment directory
mkdir -p environments/project-saas-1

# 2. Copy the project-cv structure and adapt
cp environments/project-cv/main.tf environments/project-saas-1/
cp environments/project-cv/credentials.tfvars environments/project-saas-1/

# 3. Edit main.tf: change the backend key to "project-saas-1.tfstate"
# 4. Edit main-modules.tf: change VM name, IP, specs
# 5. Create dev.tfvars with the new VM config

# 6. Initialize and apply the new project
cd environments/project-saas-1
terraform init
terraform apply -var-file=dev.tfvars -var-file=credentials.tfvars

# 7. Add the new site to the shared Nginx config:
#    Edit environments/shared/dev.tfvars → update backend_host
#    Or add a new server block to the DO droplet's Nginx
cd ../shared
terraform apply -var-file=dev.tfvars -var-file=secrets.tfvars -var-file=credentials.tfvars
```

Each project has its own state — destroying project-saas-1 won't touch the CV site or the shared edge.

## Usage

### Shared Infrastructure (DO edge + VPN gateway)
```bash
cd environments/shared
set -a && source ../../.env && set +a
terraform init
terraform plan -var-file=dev.tfvars -var-file=secrets.tfvars -var-file=credentials.tfvars
terraform apply -var-file=dev.tfvars -var-file=secrets.tfvars -var-file=credentials.tfvars
```

### Project: CV (web-CV VM)
```bash
cd environments/project-cv
set -a && source ../../.env && set +a
terraform init
terraform plan -var-file=dev.tfvars -var-file=credentials.tfvars
terraform apply -var-file=dev.tfvars -var-file=credentials.tfvars
```

## Components

| Component | State | Location | IP | Spec |
|-----------|-------|----------|----|------|
| Nginx edge + SSL | shared | DO NYC1 | 192.241.155.248 | s-1vcpu-1gb |
| WireGuard server | shared | DO droplet | 10.99.0.1 | :51820/UDP |
| VPN gateway VM | shared | Proxmox hyper101 | 192.168.0.106 | 1c/1GB/32GB |
| web-CV VM | project-cv | Proxmox hyper101 | 192.168.0.105 | 2c/2GB/32GB |
| SSL cert | shared | DO droplet | — | Let's Encrypt |
| Terraform state | — | Azure Storage | — | shared.tfstate + project-cv.tfstate |

## Reusable Modules

```
modules/
├── digitalocean-edge/   # Nginx + WireGuard + firewall + SSL-ready
└── proxmox-vm/         # Generic Proxmox VM — used by all projects
```

The `proxmox-vm` module is designed for reuse across all projects. It accepts:
- `name`, `memory`, `cores`, `disk_size` — VM specs
- `static_ip`, `gateway` — network config (or DHCP if empty)
- `ssh_keys`, `tags`, `description` — metadata

## Prerequisites

### SSH Key Pair
```bash
ls keys/
# hybrid-infra-admin      (private — gitignored)
# hybrid-infra-admin.pub  (public — in dev.tfvars)
```

### Credentials (in `.env`, gitignored)
- `DO_TOKEN` — DigitalOcean Personal Access Token
- `PM_API_TOKEN` — Proxmox API token
- `PM_ENDPOINT` — Proxmox API URL
- `ARM_*` — Azure Service Principal for state backend

### Secrets (in `environments/shared/secrets.tfvars`, gitignored)
- WireGuard private/public keys (DO + Proxmox sides)
- WireGuard preshared key

### Proxmox Template
- VM ID 104: Ubuntu 24.04 with cloud-init

## Security

### Protected
- ✅ No secrets in git (`.env`, `secrets.tfvars`, `credentials.tfvars`, `keys/` all gitignored)
- ✅ Proxmox not exposed to internet (private, outbound only)
- ✅ WireGuard encrypted tunnel
- ✅ SSL/TLS via Let's Encrypt (auto-renewing)
- ✅ HTTP → HTTPS redirect
- ✅ Separate states per project (blast radius containment)
- ✅ Terraform state in Azure with locking

### Known Issues (TODO)
- ⚠️ SSH port 22 open to world on DO droplet — restrict to known IPs
- ⚠️ PasswordAuthentication enabled on VMs — disable, key-only
- ⚠️ No UFW on Proxmox VMs — enable and restrict
- ⚠️ No security headers in Nginx (HSTS, X-Frame-Options, etc.)
- ⚠️ Java voice gateway not started on web-CV VM
- ⚠️ Credentials were shared in chat history — rotate all secrets

## Future Phases

- **Phase 2**: Data-driven multi-site Nginx config (add site = one variable entry)
- **Phase 3**: Ansible playbooks for post-Terraform provisioning
- **Phase 4**: CI/CD pipeline with GitHub Actions (plan on PR, apply on merge)
- **Phase 5**: Monitoring (Uptime Kuma, log aggregation)
