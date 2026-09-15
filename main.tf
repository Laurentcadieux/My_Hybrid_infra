terraform {
  required_version = ">= 1.7.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "hermesterraformstate"
    container_name       = "tfstate"
    key                  = "my-hybrid-infra-dev.tfstate"
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "proxmox" {
  endpoint  = var.pm_endpoint
  api_token = var.pm_api_token
  insecure  = var.pm_insecure
  ssh {
    agent = true
  }
}
