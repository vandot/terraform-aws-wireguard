variable "ssh_key_id" {
  description = "A SSH public key ID to add to the VPN instance."
}

variable "instance_type" {
  default     = "t3.micro"
  description = "The machine type to launch, some machines may offer higher throughput for higher use cases."
}

variable "network_interface_name" {
  default     = "ens5"
  description = "The name of the network interface"

}

variable "vpc_id" {
  description = "The VPC ID in which Terraform will launch the resources."
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnets for the Autoscaling Group to use for launching instances. May be a single subnet, but it must be an element in a list."
}

variable "wg_client_public_keys" {
  # type        = map(string)
  description = "List of maps of client IPs and public keys. See Usage in README for details."
}

variable "wg_server_net" {
  default     = "192.168.2.1/24"
  description = "IP range for vpn server - make sure your Client ips are in this range but not the specific ip i.e. not .1"
}

variable "wg_server_port" {
  default     = 51820
  description = "Port for the vpn server"
}

variable "wg_persistent_keepalive" {
  default     = 25
  description = "Persistent Keepalive - useful for helping connection stability over NATs"
}

variable "eip_id" {
  description = "If an EIP ID is provided the instance will attempt to switch EIP."
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = [""]
  description = "Additional security groups if provided, default empty"
}

variable "env" {
  default     = "prod"
  description = "The name of environment for WireGuard. Used to differentiate multiple deployments"
}

variable "wg_server_private_key_param" {
  default     = "/wireguard/wg-server-private-key"
  description = "The SSM parameter containing the WG server private key"
}
