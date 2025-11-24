# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.14.0"
  required_providers {
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.87.0"
    }
    # see https://registry.terraform.io/providers/lxc/incus
    # see https://github.com/lxc/terraform-provider-incus
    incus = {
      source  = "lxc/incus"
      version = "1.0.0"
    }
  }
}

provider "proxmox" {
  tmp_dir = "tmp"
  ssh {
    node {
      name    = var.proxmox_pve_node_name
      address = var.proxmox_pve_node_address
    }
  }
}

provider "incus" {
}
