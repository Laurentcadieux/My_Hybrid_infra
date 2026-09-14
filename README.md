# My_Hybrid_infra

**DigitalOcean (light edge/DMZ) + Proxmox (dual-node on-prem HA/DR)**, managed with Terraform/OpenTofu. State in Azure Storage with locking.

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │            DigitalOcean (Light Edge)         │
                    │                                             │
   Internet ──────▶│   ┌──────────────────────┐                   │
                    │   │  Nginx DMZ Droplet   │                   │
                    │   │  (reverse proxy)     │                   │
                    │   │  s-1vcpu-1gb         │                   │
                    │   └──────────┬───────────┘                   │
                    │              │ VPC 10.0.0.0/24               │
                    └──────────────┼───────────────────────────────┘
                                   │ WireGuard VPN (10.99.0.0/24)
                                   │
                    ┌──────────────┼───────────────────────────────┐
                    │     Proxmox On-Prem (Dual Node HA/DR)        │
                    │              │                               │
                    │   ┌──────────┴───────────┐                   │
                    │   │  hyper100            │   hyper101        │
                    │   │  ┌────┐  ┌────┐    │   ┌────┐  ┌────┐  │
                    │   │  │web1│  │app1│    │   │web2│  │app2│  │
                    │   │  └────┘  └────┘    │   └────┘  └────┘  │
                    │   │  ┌──────────┐     │                     │
                    │   │  │  DB (PG)  │     │   (DR replica)      │
                    │   │  └──────────┘     │                     │
                    │   └────────────────────┘                     │
                    │                                             │
                    │  Network segments:                         │
                    │    10.10.1.0/24  web front-end              │
                    │    10.10.2.0/24  app servers                 │
                    │    10.10.3.0/24  database (private)          │
                    └─────────────────────────────────────────────┘
```

## Design Principles

- **DigitalOcean footprint = light**: only Nginx reverse proxy in the DMZ. No app logic, no databases in the cloud.
- **Proxmox = real workloads**: web front-ends, app servers, and database all run on-prem.
- **Dual-node HA/DR**: VMs spread across hyper100 and hyper101. DB primary on hyper100, DR replica on hyper101.
- **Network segmentation**: web, app, and DB on separate subnets. DB subnet has no public route — only app and web subnets can reach it.
- **VPN tunnel**: WireGuard connects the DO Nginx proxy to Proxmox web VMs. No Proxmox ports exposed to the internet.

## Components

| Layer         | DigitalOcean (Edge)       | Proxmox (On-Prem)                    |
|---------------|---------------------------|--------------------------------------|
| DMZ           | Nginx reverse proxy (1 droplet) | —                              |
| Network       | VPC 10.0.0.0/24           | vmbr0 + WireGuard 10.99.0.0/24       |
| Web front-end | —                         | 2 VMs (1 per node) on 10.10.1.0/24  |
| App servers   | —                         | 2 VMs (1 per node) on 10.10.2.0/24  |
| Database      | —                         | 1 VM + DR on 10.10.3.0/24           |
| VPN           | WireGuard client          | WireGuard endpoint (web VMs)        |

## Prerequisites

### 1. SSH Key Pair (✅ Generated)
```bash
ls keys/
# hybrid-infra-admin      (private)
# hybrid-infra-admin.pub (public — paste into dev.tfvars)
```

### 2. DigitalOcean API Token (✅ Configured in .env)

### 3. Proxmox API Token (✅ Configured in .env)
- Token: `root@pam!terraform` (same token works on both hyper100 & hyper101)
- Endpoints: `https://192.168.0.100:8006/` and `https://192.168.0.101:8006/`

### 4. Azure Storage for State
Create a storage account + container, then fill in `ARM_*` vars in `.env`.

## Usage

```bash
# 1. Load credentials
set -a && source .env && set +a

# 2. Paste SSH public key into dev.tfvars
cat keys/hybrid-infra-admin.pub
# Copy the output into environments/dev/dev.tfvars (ssh_public_key field)

# 3. Init
terraform init

# 4. Plan
terraform plan -var-file="environments/dev/dev.tfvars" -out=tfplan

# 5. Apply
terraform apply tfplan
```

## Structure

```
My_Hybrid_infra/
├── main.tf                          # Providers + backend
├── modules.tf                       # Module wiring
├── variables.tf                     # All input variables
├── outputs.tf                       # Outputs
├── environments/dev/dev.tfvars     # Dev config
├── modules/
│   ├── digitalocean-vpc/            # Edge VPC
│   ├── digitalocean-nginx-dmz/      # Nginx reverse proxy + VPN client
│   ├── proxmox-web/                 # Web front-end VMs (both nodes)
│   ├── proxmox-app/                 # App server VMs (both nodes)
│   └── proxmox-db/                  # Database VM + DR replica
├── keys/                            # SSH keys (gitignored)
├── scripts/setup.sh                # Setup helper
├── .github/workflows/terraform.yml # CI/CD
├── .env.example                     # Credential template
├── .env                             # Real credentials (gitignored)
├── .gitignore
└── README.md
```

## Security

- All secrets via `.env` (gitignored) — never committed
- SSH keys in `keys/` (gitignored)
- DB subnet private — only web/app subnets can reach it
- No Proxmox ports exposed to internet — VPN only
- State remote (Azure Storage) with locking
- CI/CD uses GitHub Secrets
