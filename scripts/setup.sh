#!/usr/bin/env bash
set -euo pipefail

echo "=== My_Hybrid_infra Setup ==="
echo ""

# Check for .env
if [ ! -f .env ]; then
  echo "⚠️  No .env file found. Copy .env.example and fill in your credentials:"
  echo "   cp .env.example .env"
  echo ""
  echo "You need:"
  echo "  - DigitalOcean Personal Access Token (DO_TOKEN)"
  echo "  - Proxmox API Token ID (PM_API_TOKEN_ID)"
  echo "  - Proxmox API Token Secret (PM_API_TOKEN_SECRET)"
  echo "  - Proxmox Endpoint URL (PM_ENDPOINT)"
  echo "  - Azure Service Principal (ARM_CLIENT_ID, ARM_CLIENT_SECRET)"
  echo "  - Azure Subscription ID (ARM_SUBSCRIPTION_ID)"
  echo "  - Azure Tenant ID (ARM_TENANT_ID)"
  echo ""
  exit 1
fi

# Load environment
set -a
source .env
set +a

echo "✅ Environment loaded from .env"
echo ""

# Check required vars
for var in DO_TOKEN PM_API_TOKEN_ID PM_API_TOKEN_SECRET PM_ENDPOINT; do
  if [ -z "${!var:-}" ] || [ "${!var}" = "your-"*"-token" ]; then
    echo "❌ $var is not set or has placeholder value in .env"
    exit 1
  fi
done

echo "✅ All required API tokens present"
echo ""

# Initialize Terraform
echo "=== Running terraform init ==="
terraform init

echo ""
echo "=== Running terraform plan ==="
terraform plan -var-file="environments/dev/dev.tfvars" -out=tfplan

echo ""
echo "✅ Plan generated. Review it, then run:"
echo "   terraform apply tfplan"
