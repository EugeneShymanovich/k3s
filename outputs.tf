output "ssh_cidr" {
  description = "CIDR currently allowed to reach ports 22 and 6443"
  value       = local.ssh_cidr
}

output "nodes" {
  description = "Nodes with public and private IPs"
  value = {
    for name, server in hcloud_server.node : name => {
      public_ip  = server.ipv4_address
      private_ip = local.nodes[name]
      role       = startswith(name, "k3s-cp") ? "control-plane" : "worker"
    }
  }
}

output "cp1" {
  description = "Control-plane connection details"
  value = {
    public_ip  = hcloud_server.node["k3s-cp1"].ipv4_address
    private_ip = local.nodes["k3s-cp1"]
  }
}

output "ssh_command" {
  description = "Example SSH command for the control-plane"
  value       = "ssh root@${hcloud_server.node["k3s-cp1"].ipv4_address}"
}
