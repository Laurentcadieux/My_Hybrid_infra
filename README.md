# My_Hybrid_infra

Hybrid infrastructure: **DigitalOcean (cloud) + Proxmox (on-prem)**, managed with Terraform/OpenTofu. State stored in Azure Storage with locking.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     DigitalOcean (Cloud)                        │
│                                                                 │
│  ┌──────────┐    ┌─────────────┐    ┌────────────────────┐     │
│  │  Load     │───▶│  Droplets   │───▶│  Managed Database  │     │
│  │ Balancer │    │  (web app)  │    │  (PostgreSQL)       │     │
│  │ (public) │    │  (private)  │    │  (private)          │     │
│  └──────────┘    └─────────────┘    └────────────────────┘     │
│       │              │                      │                   │
│       │         ┌────┴────┐                 │                   │
│       │         │  VPC    │─────────────────┘                   │
│       │         │ 10.0/16 │                                     │
│       │         └────┬────┘                                     │
└───────┼──────────────┼──────────────────────────────────────────┘
        │              │
        │         VPN / WireGuard
        │              │
┌───────┼──────────────┼──────────────────────────────────────────┐
│       │         ┌────┴────┐                                      │
│       │         │  vmbr0  │                                      │
│       │         └────┬────┘                                      │
│       │              │                                           │
│  ┌────┴────┐   ┌──────┴──────┐                                   │
│  │  LB     │   │  Proxmox VM │                                   │
│  │ (on-prem│   │  (web app)  │                                   │
│  │  backup)│   │  Debian 12  │                                   │
│  └─────────┘   └─────────────┘                                   │
│                     Proxmox (On-Prem)                            │
└──────────────────────────────────────────────────────────────────┘
```

## Components

| Layer         | Cloud (DigitalOcean)          | On-Prem (Proxmox)       |
|---------------|-------------------------------|-------------------------|
| Network       | VPC (10.0.0.0/16)             | vmbr0 bridge            |
| Load Balancer | DigitalOcean LB (public IP)   | (optional on-prem LB)   |
| Compute       | Droplets (s-2vcpu-4gb x2)     | VM (2 vCPU, 4GB, 30GB)  |
| Database      | Managed PostgreSQL            | (uses DO managed DB)    |
| SSH Access    | Key: `keys/hybrid-infra-admin`| Same key via cloud-init |

## Prerequisites

### 1. SSH Key Pair (✅ Generated)
```bash
ls keys/
# hybrid-infra-admin      (private key)
# hybrid-infra-admin.pub  (public key)
```

### 2. DigitalOcean API Token
1. Go to https://cloud.digitalocean.com/account/api/tokens
2. Generate a Personal Access Token (write scope)
3. Add to `.env`: `DO_TOKEN=your_token`

### 3. Proxmox API Token
1. Log into Proxmox web UI
2. Datacenter → Permissions → API Tokens → Add
3. Create a token for your user (e.g., `user@pve!terraform`)
4. Add to `.env`:
   ```
   PM_API_TOKEN_ID=user@pve!terraform
   PM_API_TOKEN_SECRET=your_secret
   PM_ENDPOINT=https://proxmox-host:8006/
   ```

### 4. Azure Storage for State
1. Create an Azure Storage Account with a blob container named `tfstate`
2. Create a Service Principal with access to the storage account
3. Fill in the `ARM_*` variables in `.env`

## Usage

```bash
# 1. Copy .env.example and fill in credentials
cp .env.example .env
# Edit .env with your real tokens

# 2. Load environment
set -a && source .env && set +a

# 3. Initialize Terraform
terraform init

# 4. Update dev.tfvars with your SSH public key
# Get it: cat keys/hybrid-infra-admin.pub
# Paste it into environments/dev/dev.tfvars

# 5. Plan
terraform plan -var-file="environments/dev/dev.tfvars" -out=tfplan

# 6. Apply
terraform apply tfplan
```

## Structure

```
My_Hybrid_infra/
├── main.tf                    # Root: providers + backend
├── modules.tf                 # Root: module calls
├── variables.tf               # Root: input variables
├── outputs.tf                 # Root: outputs
├── environments/
│   └── dev/
│       └── dev.tfvars         # Dev environment config
├── modules/
│   ├── digitalocean-vpc/      # VPC networking
│   ├── digitalocean-ssh-key/  # SSH key management
│   ├── digitalocean-droplet/  # Web app droplets
│   ├── digitalocean-loadbalancer/ # Public load balancer
│   ├── digitalocean-database/ # Managed PostgreSQL
│   └── proxmox-vm/            # On-prem VMs
├── keys/                      # SSH keys (gitignored)
├── scripts/
│   └── setup.sh               # Setup helper
├── .github/workflows/
│   └── terraform.yml          # CI/CD pipeline
├── .env.example               # Credential template
├── .gitignore
└── README.md
```

## Security

- All secrets via environment variables — never committed to git
- SSH keys in `keys/` directory (gitignored)
- `.env` is gitignored
- State is remote (Azure Storage) with locking
- CI/CD uses GitHub OIDC (no long-lived cloud keys)

## CI/CD

GitHub Actions workflow at `.github/workflows/terraform.yml`:
- **PRs**: `fmt -check`, `init`, `validate`, `plan`
- **Push to main**: `apply -auto-approve`
- Requires GitHub secrets for all cloud credentials
