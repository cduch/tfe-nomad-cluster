output "nomad_server_private_ips" {
  value = aws_instance.server.*.private_ip
}

output "nomad_server_public_ips" {
  value = aws_instance.server[*].public_ip
}

output "nomad_client_private_ips" {
  value = aws_instance.client.*.private_ip
}

output "nomad_client_public_ips" {
  value = aws_instance.client[*].public_ip
}

locals {
  cert-san = [for f in range(1, var.server_count +1): 
  {
    #value = f
    #something_else = "${f}"
    foo = "${var.server_name}-0${f}"
  }
  ]
}

#format("${var.server_name}-%02d", count.index + 1)


output "certs4" {
  value = local.cert-san
}

# output "nomad_apt" {
#   value = local.nomad_apt
# }

# output "consul_apt" {
#   value = local.consul_apt
# }

# output "vault_apt" {
#   value = local.vault_apt
# }