output "nomad_server_private_ips" {
  value = aws_instance.nomad_server.*.private_ip
}

output "nomad_server_public_ips" {
  value = aws_instance.nomad_server[*].public_ip
}

output "nomad_client_private_ips" {
  value = aws_instance.nomad_client.*.private_ip
}

output "nomad_client_public_ips" {
  value = aws_instance.nomad_client[*].public_ip
}