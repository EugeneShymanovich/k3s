locals {
  network_zone = "eu-central"

  # Static private IPs so k3s flags and worker join commands stay stable.
  nodes = {
    "k3s-cp1" = "10.0.0.11"
    "k3s-w1"  = "10.0.0.21"
    "k3s-w2"  = "10.0.0.22"
  }

  private_cidr = "10.0.0.0/24"
}

# Detect the operator's current public IP when ssh_cidr is not provided.
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  ssh_cidr = coalesce(var.ssh_cidr, "${chomp(data.http.my_ip.response_body)}/32")
}

resource "hcloud_ssh_key" "admin" {
  name       = "${var.cluster_name}-admin"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "hcloud_network" "private" {
  name     = var.network_name
  ip_range = local.private_cidr
}

resource "hcloud_network_subnet" "private" {
  type         = "cloud"
  network_id   = hcloud_network.private.id
  network_zone = local.network_zone
  ip_range     = local.private_cidr
}

resource "hcloud_firewall" "cluster" {
  name = "${var.cluster_name}-fw"

  # Public SSH only from the operator.
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = [local.ssh_cidr]
    description = "SSH from operator"
  }

  # k3s API access for kubectl from the operator only. Never 0.0.0.0/0.
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = [local.ssh_cidr]
    description = "k3s API from operator"
  }

  # Full access inside the private network (kubelet, VXLAN, etcd, DNS...).
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "any"
    source_ips  = [local.private_cidr]
    description = "intra-cluster TCP"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "any"
    source_ips  = [local.private_cidr]
    description = "intra-cluster UDP/VXLAN"
  }
  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = [local.private_cidr]
    description = "intra-cluster ICMP"
  }
}

resource "hcloud_server" "node" {
  for_each = local.nodes

  name         = each.key
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.cluster.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    subnet_id = hcloud_network_subnet.private.id
    ip        = each.value
    alias_ips = []
  }

  labels = {
    cluster = var.cluster_name
    role    = startswith(each.key, "k3s-cp") ? "control-plane" : "worker"
  }

  depends_on = [hcloud_network_subnet.private]
}

# ---------------------------------------------------------------------------
# Generated Ansible inventory (never committed, see .gitignore).
# Regenerated on every apply, so IPs are always in sync with the infra.
# ---------------------------------------------------------------------------
locals {
  ssh_private_key_path = trimsuffix(var.ssh_public_key_path, ".pub")

  inventory_nodes = {
    for name, server in hcloud_server.node : name => {
      public_ip  = server.ipv4_address
      private_ip = local.nodes[name]
      group      = startswith(name, "k3s-cp") ? "control_plane" : "workers"
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory/hosts.ini"

  content = templatefile("${path.module}/templates/inventory.tpl", {
    inventory_nodes = local.inventory_nodes
    ansible_user    = "root"
    ssh_key_path    = local.ssh_private_key_path
  })

  file_permission = "0600"
}
