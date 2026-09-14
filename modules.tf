# ─── DigitalOcean VPC ────────────────────────────────────────
module "do_vpc" {
  source = "./modules/digitalocean-vpc"

  name       = "${var.project_name}-${var.environment}"
  region     = var.region
  ip_range   = "10.0.0.0/16"
  description = "VPC for ${var.project_name} ${var.environment}"
}

# ─── SSH Key ─────────────────────────────────────────────────
module "do_ssh_key" {
  source = "./modules/digitalocean-ssh-key"

  name        = "${var.project_name}-${var.environment}"
  public_key  = var.ssh_public_key
}

# ─── Web App Droplets ────────────────────────────────────────
module "do_droplet" {
  source = "./modules/digitalocean-droplet"

  name          = "${var.project_name}-${var.environment}-web"
  region        = var.region
  size          = var.do_droplet_size
  count         = var.do_droplet_count
  vpc_uuid      = module.do_vpc.id
  ssh_key_id    = module.do_ssh_key.id
  tags          = ["${var.project_name}", var.environment, "web"]
}

# ─── Load Balancer ───────────────────────────────────────────
module "do_loadbalancer" {
  source = "./modules/digitalocean-loadbalancer"

  name           = "${var.project_name}-${var.environment}-lb"
  region         = var.region
  vpc_uuid       = module.do_vpc.id
  droplet_ids    = module.do_droplet.ids
  droplet_count  = var.do_droplet_count
  port           = 80
  target_port    = 80
  algorithm      = "round_robin"
}

# ─── Managed Database ────────────────────────────────────────
module "do_database" {
  source = "./modules/digitalocean-database"

  name        = "${var.project_name}-${var.environment}-db"
  region      = var.region
  engine      = var.do_db_engine
  size        = var.do_db_size
  node_count  = var.do_db_node_count
  vpc_uuid    = module.do_vpc.id
}

# ─── Proxmox On-Prem VMs ─────────────────────────────────────
module "proxmox_vm" {
  source = "./modules/proxmox-vm"

  count          = var.pm_vm_count
  vm_name        = "${var.project_name}-${var.environment}-onprem"
  node_name      = var.pm_node_name
  template       = var.pm_vm_template
  memory         = var.pm_vm_memory
  cores          = var.pm_vm_cores
  disk_size      = var.pm_vm_disk_size
  bridge         = var.pm_bridge_name
  ssh_keys       = [var.ssh_public_key]
}
