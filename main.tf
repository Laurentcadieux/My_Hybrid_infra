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
    # Values come from environment variables:
    # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
    # ARM_RESOURCE_GROUP, ARM_STORAGE_ACCOUNT, ARM_CONTAINER_NAME
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "my-hybrid-infra-dev.tfstate"
  }
}

provider "digitalocean" {
  # Token from environment: DO_TOKEN
  token = var.do_token
}

provider "proxmox" {
  endpoint = var.pm_endpoint
  api_token = var.pm_api_token
  insecure = var.pm_insecure # set to false in production with valid certs
  ssh {
    agent = true
  }
}
