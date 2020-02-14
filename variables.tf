variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "whitelist_ip" {
  default = "0.0.0.0/0"
}

variable "instance_type" {
  description = "type of EC2 instance to provision."
  default     = "t2.small"
}

variable "name" {
  description = "name to pass to Name tag"
  default     = "js-nomad"
}

variable "key_name" {
  description = "SSH key to connect to EC2 instances. Use the one that is already uploaded into your AWS region or add one to main.tf"
  default     = "joestack"
}

variable "network_address_space" {
  description = "The default CIDR to use"
  default     = "172.16.0.0/16"
}

variable "data_dir" {
  description = "Nomad config option"
  default     = "/opt/nomad"
}

variable "bind_addr" {
  description = "Nomad config option"
  default     = "0.0.0.0"
}
variable "datacenter" {
  default = "dc1"
}

variable "region" {
  default = "global"
}


variable "server" {
  description = "enable nomad as server option?"
  default     = "true"
}
variable "server_count" {
  description = "amount of nomad servers (odd number 1,3, max 5)"
  default     = "3"
}

variable "server_name" {
  default = "nomad-s"
}

variable "client" {
  description = "enable nomad client option?"
  default     = "true"
}
variable "client_count" {
  description = "amount of nomad clients?"
  default     = "4"
}
variable "client_name" {
  default = "nomad-c"
}
variable "tag_key" {
  description = "Server rejoin tag_key to identify nomad servers within a region"
  default     = "js_nomad_tag"
}

variable "tag_value" {
  description = "Server rejoin tag_value to identify nomad servers within a region"
  default     = "js_nomad_value"
}


variable "root_block_device_size" {
  default = "20"
}

variable "nomad_version" {
  default = "0.10.3"
}
