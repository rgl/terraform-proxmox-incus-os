output "nodes" {
  value = join(",", [for node in local.nodes : node.ip_address])
}
