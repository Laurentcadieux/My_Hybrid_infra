terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "name" {
  type        = string
  description = "Database cluster name"
}

variable "region" {
  type        = string
  description = "DigitalOcean region"
}

variable "engine" {
  type        = string
  description = "Database engine (pg or mysql)"
  default     = "pg"
}

variable "size" {
  type        = string
  description = "Database node size"
  default     = "db-s-1vcpu-1gb"
}

variable "node_count" {
  type        = number
  description = "Number of DB nodes (1 for dev)"
  default     = 1
}

variable "vpc_uuid" {
  type        = string
  description = "VPC UUID for private networking"
}

variable "db_name" {
  type        = string
  description = "Database name to create"
  default     = "webapp"
}

variable "db_user" {
  type        = string
  description = "Database user"
  default     = "webapp"
}

resource "digitalocean_database_cluster" "this" {
  name       = var.name
  engine     = var.engine
  version    = var.engine == "pg" ? "15" : "8"
  size       = var.size
  region     = var.region
  node_count  = var.node_count
  vpc_uuid    = var.vpc_uuid
}

resource "digitalocean_database_db" "app" {
  cluster_id = digitalocean_database_cluster.this.id
  name       = var.db_name
}

resource "digitalocean_database_user" "app" {
  cluster_id = digitalocean_database_cluster.this.id
  name       = var.db_user
}

output "private_uri" {
  value     = digitalocean_database_cluster.this.private_uri
  sensitive = true
}

output "host" {
  value     = digitalocean_database_cluster.this.private_host
  sensitive = true
}

output "port" {
  value = digitalocean_database_cluster.this.port
}

output "database" {
  value = digitalocean_database_db.app.name
}

output "user" {
  value = digitalocean_database_user.app.name
}
