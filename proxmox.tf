locals {
  cluster_node_network_prefix_length = tonumber(regex("/([0-9]{1,2})$", var.cluster_node_network)[0])
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.91.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_file" "incus_os" {
  node_name    = var.proxmox_pve_node_name
  datastore_id = "local"
  content_type = "iso"
  source_file {
    path      = "tmp/incus-os/incus-os-${var.incus_os_version}.qcow2"
    file_name = "incus-os-${var.incus_os_version}.img"
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.91.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_file" "incus_os_seed_data" {
  count        = var.node_count
  node_name    = var.proxmox_pve_node_name
  datastore_id = "local"
  content_type = "iso"
  source_file {
    file_name = "${var.prefix}-${local.nodes[count.index].name}-seed-data.iso"
    path      = "tmp/incus-os-seed-data-${local.nodes[count.index].name}.iso"
  }
  depends_on = [terraform_data.incus_os_seed_data]
}

# see https://developer.hashicorp.com/terraform/language/resources/terraform-data
resource "terraform_data" "incus_os_seed_data" {
  count = var.node_count

  triggers_replace = {
    iso_path = "tmp/incus-os-seed-data-${local.nodes[count.index].name}.iso"

    # see https://github.com/lxc/incus-os/blob/202601021903/incus-osd/api/system_network.go
    network_config = yamlencode({
      version = "1"
      dns = {
        hostname    = local.nodes[count.index].name
        domain      = "test"
        nameservers = [var.cluster_node_network_gateway]
      }
      time = {
        ntp_servers = ["pt.pool.ntp.org"]
      }
      interfaces = [
        {
          name      = "eth0"
          hwaddr    = local.nodes[count.index].mac_address
          addresses = ["${local.nodes[count.index].ip_address}/${local.cluster_node_network_prefix_length}"]
          routes = [
            {
              to  = "0.0.0.0/0"
              via = var.cluster_node_network_gateway
            }
          ]
        }
      ]
    })

    incus_config = yamlencode({
      version        = "1"
      apply_defaults = true
      preseed = {
        certificates = [
          {
            name        = "admin"
            type        = "client"
            description = "Initial admin client"
            certificate = var.incus_client_certificate
          }
        ]
      }
    })

    applications_config = yamlencode({
      version = "1"
      applications = [
        {
          name = "incus"
        }
      ]
    })
  }

  provisioner "local-exec" {
    when = create
    environment = {
      INCUS_OS_SEED_DATA_COMMAND             = "create"
      INCUS_OS_SEED_DATA_ISO_PATH            = self.triggers_replace.iso_path
      INCUS_OS_SEED_DATA_NETWORK_CONFIG      = self.triggers_replace.network_config
      INCUS_OS_SEED_DATA_INCUS_CONFIG        = self.triggers_replace.incus_config
      INCUS_OS_SEED_DATA_APPLICATIONS_CONFIG = self.triggers_replace.applications_config
    }
    interpreter = ["bash"]
    command     = "${path.module}/incus-os-seed-data-iso.sh"
  }

  provisioner "local-exec" {
    when = destroy
    environment = {
      INCUS_OS_SEED_DATA_COMMAND  = "destroy"
      INCUS_OS_SEED_DATA_ISO_PATH = self.triggers_replace.iso_path
    }
    interpreter = ["bash"]
    command     = "${path.module}/incus-os-seed-data-iso.sh"
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.91.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "incus_os" {
  count           = var.node_count
  name            = "${var.prefix}-${local.nodes[count.index].name}"
  node_name       = var.proxmox_pve_node_name
  tags            = sort(["incus-os", "example", "terraform"])
  stop_on_destroy = true
  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  smbios {
    uuid = local.nodes[count.index].uuid
  }
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = 4
  }
  memory {
    dedicated = 4 * 1024
  }
  vga {
    type = "qxl"
  }
  network_device {
    mac_address = local.nodes[count.index].mac_address
    bridge      = "vmbr0"
  }
  rng {
    source = "/dev/urandom"
  }
  tpm_state {
    version = "v2.0"
  }
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }
  cdrom {
    interface = "ide3"
    file_id   = proxmox_virtual_environment_file.incus_os_seed_data[count.index].id
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = 50
    file_format  = "raw"
    file_id      = proxmox_virtual_environment_file.incus_os.id
  }
  # NB incus os does not have a qemu agent (aka guest tools), and probably never will.
  #    see https://github.com/lxc/incus-os/issues/325
  # agent {
  #   enabled = true
  #   trim    = true
  # }
  # NB incus does not support a cloud-init drive, and probably never will.
  #    see https://github.com/lxc/incus-os/issues/325
  # initialization {
  #   ip_config {
  #     ipv4 {
  #       address = "${local.nodes[count.index].address}/24"
  #       gateway = var.cluster_node_network_gateway
  #     }
  #   }
  # }
}
