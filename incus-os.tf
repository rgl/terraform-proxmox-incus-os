locals {
  nodes = [
    for i in range(var.node_count) : {
      name        = "incus${i}"
      ip_address  = cidrhost(var.cluster_node_network, var.cluster_node_network_first_node_hostnum + i)
      mac_address = format("bc:24:11:00:00:%02x", i + 1)
      uuid        = format("00000000-0000-0000-0000-bc24110000%02x", i + 1)
    }
  ]
}
