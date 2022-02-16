resource "tls_private_key" "ca" {
  count = var.vault_tls_enabled ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
    count = var.vault_tls_enabled ? 1 : 0
  key_algorithm     = tls_private_key.ca[count.index].algorithm
  private_key_pem   = tls_private_key.ca[count.index].private_key_pem
  is_ca_certificate = true

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "server_auth",
  ]
  
  #dns_names = ["${var.dns_domain}"]
  
  subject {
    common_name  = "${var.common_name}"
    organization = "${var.organization}"
  }
}

resource "tls_private_key" "vault" {
    count = var.vault_tls_enabled ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "vault" {
    count = var.vault_tls_enabled ? 1 : 0
  key_algorithm   = tls_private_key.vault[count.index].algorithm
  private_key_pem = tls_private_key.vault[count.index].private_key_pem
  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  dns_names = [
    "*.${var.dns_domain}"
    ]
  

  ip_addresses   = [
     "127.0.0.1"
      ]
}

resource "tls_locally_signed_cert" "vault" {
    count = var.vault_tls_enabled ? 1 : 0
  cert_request_pem = tls_cert_request.vault[count.index].cert_request_pem

  ca_key_algorithm   = tls_private_key.ca[count.index].algorithm
  ca_private_key_pem = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[count.index].cert_pem

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}