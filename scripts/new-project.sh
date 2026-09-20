#!/usr/bin/env bash
# Create a new project environment from the template
# Usage: ./scripts/new-project.sh my-saas 192.168.0.110 4096 4 50
set -euo pipefail

PROJECT_NAME="${1:?Usage: $0 <project-name> <vm-ip> [memory-mb] [cores] [disk-gb]}"
VM_IP="${2:?VM IP required (e.g., 192.168.0.110)}"
MEMORY="${3:-2048}"
CORES="${4:-2}"
DISK="${5:-32}"

TEMPLATE="environments/project-template"
TARGET="environments/project-${PROJECT_NAME}"

if [ -d "$TARGET" ]; then
  echo "Error: $TARGET already exists"
  exit 1
fi

cp -r "$TEMPLATE" "$TARGET"

# Replace placeholders
sed -i "s/CHANGEME-vm/${PROJECT_NAME}-vm/g" "$TARGET/dev.tfvars" "$TARGET/main-modules.tf"
sed -i "s/CHANGEME/${PROJECT_NAME}/g" "$TARGET/dev.tfvars"
sed -i "s/192.168.0.X/${VM_IP}/g" "$TARGET/dev.tfvars"
sed -i "s/^vm_memory.*=.*/vm_memory = ${MEMORY}/" "$TARGET/dev.tfvars"
sed -i "s/^vm_cores.*=.*/vm_cores = ${CORES}/" "$TARGET/dev.tfvars"
sed -i "s/^vm_disk.*=.*/vm_disk = ${DISK}/" "$TARGET/dev.tfvars"

# Set unique backend key
sed -i "s/CHANGEME.tfstate/project-${PROJECT_NAME}.tfstate/" "$TARGET/main.tf"

# Copy credentials
if [ -f "environments/shared/credentials.tfvars" ]; then
  cp environments/shared/credentials.tfvars "$TARGET/"
fi

echo ""
echo "✅ Project '${PROJECT_NAME}' created at ${TARGET}"
echo ""
echo "Next steps:"
echo "  cd ${TARGET}"
echo "  terraform init"
echo "  terraform apply -var-file=dev.tfvars -var-file=credentials.tfvars"
echo ""
echo "Then add to environments/shared/main-modules.tf sites map:"
echo "  \"${PROJECT_NAME}\" = {"
echo "    domain       = \"YOUR-DOMAIN\""
echo "    backend_ip   = \"${VM_IP}\""
echo "    backend_port = 80"
echo "    ssl          = true"
echo "  }"
echo ""
echo "Then apply shared:"
echo "  cd environments/shared"
echo "  terraform apply -var-file=dev.tfvars -var-file=secrets.tfvars -var-file=credentials.tfvars"
