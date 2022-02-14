provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

locals {
  mod_az = length(data.aws_availability_zones.available.names)
  #mod_az = length(split(",", join(", ",data.aws_availability_zones.available.names)))
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_vpc" "hashicorp_vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hashicorp_vpc.id

}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.hashicorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name}-IGW"
  }

}

resource "aws_route_table_association" "nomad-subnet" {
  count          = var.server_count
  subnet_id      = element(aws_subnet.nomad_subnet.*.id, count.index)
  route_table_id = aws_route_table.rtb.id
}


resource "aws_subnet" "nomad_subnet" {
  count                   = var.server_count
  vpc_id                  = aws_vpc.hashicorp_vpc.id
  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index + 1)
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[count.index % local.mod_az]

  tags = {
    Name = "${var.name}-subnet"
  }
}

resource "aws_security_group" "primary" {
  name   = var.name
  vpc_id = aws_vpc.hashicorp_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  # Nomad
  ingress {
    from_port   = 4646
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = [var.whitelist_ip]
  }


  # ingress {
  #   from_port   = 8300
  #   to_port     = 8300
  #   protocol    = "tcp"
  #   cidr_blocks = [var.whitelist_ip]
  # }


  # Vault
  ingress {
    from_port   = 8200
    to_port     = 8202
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Vault
  ingress {
    from_port   = 8300
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  # ingress {
  #   from_port   = 8301
  #   to_port     = 8301
  #   protocol    = "tcp"
  #   cidr_blocks = [var.whitelist_ip]
  # }

  # ingress {
  #   from_port   = 8301
  #   to_port     = 8301
  #   protocol    = "udp"
  #   cidr_blocks = [var.whitelist_ip]
  # }


  # ingress {
  #   from_port   = 8302
  #   to_port     = 8302
  #   protocol    = "tcp"
  #   cidr_blocks = [var.whitelist_ip]
  # }


  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = [var.whitelist_ip]
  }


  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Consul
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }


  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Consul
  ingress {
    from_port   = 20000
    to_port     = 29999
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }
  # Consul
  ingress {
    from_port   = 30000
    to_port     = 39999
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}





resource "aws_iam_instance_profile" "nomad_join" {
  name = var.name
  role = aws_iam_role.nomad_join.name
}
resource "aws_iam_policy" "nomad_join" {
  name = var.name
  description = "Allows Nomad nodes to describe instances for joining."
  policy = data.aws_iam_policy_document.nomad-server.json
}
resource "aws_iam_role" "nomad_join" {
  name = var.name
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}
resource "aws_iam_policy_attachment" "nomad_join" {
  name = var.name
  roles      = [aws_iam_role.nomad_join.name]
  policy_arn = aws_iam_policy.nomad_join.arn
}
data "aws_iam_policy_document" "nomad-server" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#### VAULT CERT AND KMS UNSEAL ####

resource "aws_kms_key" "kms_key_vault" {
 description             = "Vault KMS key"
}

resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "${tls_private_key.ca.algorithm}"
  private_key_pem   = "${tls_private_key.ca.private_key_pem}"
  is_ca_certificate = true

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "server_auth",
  ]
  
  
  subject {
    common_name  = "${var.common_name}"
    organization = "${var.organization}"
  }
}

resource "tls_private_key" "vault" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "vault" {
  key_algorithm   = "${tls_private_key.vault.algorithm}"
  private_key_pem = "${tls_private_key.vault.private_key_pem}"
  subject {
    common_name  = "${var.common_name}"
    organization = "${var.organization}"
  }

  # dns_names = [
  #   "*.${var.dns_domain}"
  #   ]
  

  ip_addresses   = [
     "127.0.0.1"
      ]
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem = tls_cert_request.vault.cert_request_pem

  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}