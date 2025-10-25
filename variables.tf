variable "proxmox_pve_node_name" {
  type    = string
  default = "pve"
}

variable "proxmox_pve_node_address" {
  type = string
}

# see https://github.com/lxc/incus-os/tags
variable "incus_os_version" {
  type = string
  # renovate: datasource=github-tags depName=lxc/incus-os
  default = "202510240220"
  validation {
    condition     = can(regex("^\\d+", var.incus_os_version))
    error_message = "Must be a version number."
  }
}

variable "incus_client_certificate" {
  type = string
  validation {
    condition     = can(regex("^-----BEGIN CERTIFICATE-----", var.incus_client_certificate))
    error_message = "Must be a certificate as returned by incus remote get-client-certificate."
  }
}

variable "cluster_node_network_gateway" {
  description = "The IP network gateway of the cluster nodes"
  type        = string
  default     = "192.168.8.1"
  validation {
    condition     = can(cidrnetmask("${var.cluster_node_network_gateway}/32"))
    error_message = "Must be a valid IPv4 address."
  }
}

variable "cluster_node_network" {
  description = "The IP network CIDR block of the cluster nodes"
  type        = string
  default     = "192.168.8.0/24"
  validation {
    condition     = can(cidrnetmask(var.cluster_node_network))
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}

variable "cluster_node_network_first_node_hostnum" {
  description = "The hostnum of the first node host"
  type        = number
  default     = 80
}

variable "node_count" {
  type    = number
  default = 1
  validation {
    condition     = var.node_count >= 1
    error_message = "Must be 1 or more."
  }
}

variable "prefix" {
  type    = string
  default = "incus-os-example"
}
