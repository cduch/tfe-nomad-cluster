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


# output "nomad_apt" {
#   value = local.nomad_apt
# }

# output "consul_apt" {
#   value = local.consul_apt
# }

# output "vault_apt" {
#   value = local.vault_apt
# }