locals {
  nomad_apt  = length(split("+", var.nomad_version)) == 2 ? "nomad-enterprise" : "nomad"
  consul_apt = length(split("+", var.consul_version)) == 2 ? "consul-enterpise" : "consul"
  vault_apt  = length(split("+", var.vault_version)) == 2 ? "vault-enterprise" : "vault"
}




data "template_file" "server" {
  count = var.server_count
  template = "${join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/server.sh")
  ]))}"
  vars = {
    server_count        = var.server_count
    data_dir            = var.data_dir
    bind_addr           = var.bind_addr
    datacenter          = var.datacenter
    region              = var.region
    server              = var.server
    nomad_join          = var.tag_value
    node_name           = format("${var.server_name}-%02d", count.index +1)
    nomad_enabled       = var.nomad_enabled
    nomad_version       = var.nomad_version
    nomad_apt           = local.nomad_apt
    nomad_lic           = var.nomad_lic
    nomad_bootstrap     = var.nomad_bootstrap
    consul_enabled      = var.consul_enabled
    consul_version      = var.consul_version
    consul_apt          = local.consul_apt
    consul_lic          = var.consul_lic
    vault_enabled       = var.vault_enabled
    vault_version       = var.vault_version
    vault_apt           = local.vault_apt
    vault_lic           = var.vault_lic
    kms_key_id          = aws_kms_key.kms_key_vault.key_id
    cert                = tls_locally_signed_cert.vault.cert_pem
    key                 = tls_private_key.vault.private_key_pem
    ca_cert             = tls_private_key.ca.public_key_pem
  }
}

data "template_cloudinit_config" "server" {
  count = var.server_count
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.server.*.rendered, count.index)
  }
}

resource "aws_instance" "server" {
  count                       = var.server_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.nomad_subnet.*.id, count.index)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.primary.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.nomad_join.name

  tags = {
    Name     = format("${var.server_name}-%02d", count.index + 1)
    nomad_join  = var.tag_value
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  # ebs_block_device  {
  #   device_name           = "/dev/xvdd"
  #   volume_type           = "gp2"
  #   volume_size           = var.ebs_block_device_size
  #   delete_on_termination = "true"
  # }

  user_data = element(data.template_cloudinit_config.server.*.rendered, count.index)
}