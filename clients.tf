
data "template_file" "nomad_client" {
  count = var.client_count
  template = "${join("\n", list(
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/client.sh")
  ))}"
  vars = {
    client_count        = var.client_count
    data_dir            = var.data_dir
    bind_addr           = var.bind_addr
    datacenter          = var.datacenter
    region              = var.region
    server              = var.server
    nomad_join          = var.tag_value
    node_name           = format("${var.client_name}-%02d", count.index +1)
    nomad_version       = var.nomad_version
  }
}

data "template_cloudinit_config" "client" {
  count = var.client_count
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.nomad_client.*.rendered, count.index)
  }
}

resource "aws_instance" "nomad_client" {
  count                       = var.client_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.nomad_subnet.*.id, count.index)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.primary.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.nomad_join.name

  tags = {
    Name     = format("${var.client_name}-%02d", count.index + 1)
    nomad_join  = var.tag_value
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = element(data.template_cloudinit_config.client.*.rendered, count.index)
}