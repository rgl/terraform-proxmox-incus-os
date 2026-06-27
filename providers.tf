# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.15.7"
  required_providers {
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.0"
    }
    # see https://registry.terraform.io/providers/lxc/incus
    # see https://github.com/lxc/terraform-provider-incus
    incus = {
      source  = "lxc/incus"
      version = "1.1.1"
    }
  }
}

provider "proxmox" {
  tmp_dir = "tmp"
  ssh {
    username = var.proxmox_pve_node_username
    node {
      name    = var.proxmox_pve_node_name
      address = var.proxmox_pve_node_address
    }
  }
}

provider "incus" {
}
