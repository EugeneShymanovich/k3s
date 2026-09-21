variable "hcloud_token" {
  description = "Hetzner Cloud API token (project-scoped, read/write)"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner location for all nodes"
  type        = string
  default     = "hel1"
}

variable "server_type" {
  description = "Server type: 2 vCPU / 4 GB / 40 GB"
  type        = string
  default     = "cx23"
}

variable "image" {
  description = "OS image (Hetzner LTS name)"
  type        = string
  default     = "ubuntu-26.04"
}

variable "cluster_name" {
  description = "Prefix for all created resource names"
  type        = string
  default     = "k3s"
}

variable "network_name" {
  description = "Private network name"
  type        = string
  default     = "k3s-private"
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key injected into all nodes"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach 22 and 6443 from the internet. If null, the current public IP is detected."
  type        = string
  default     = null
}
