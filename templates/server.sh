#!/bin/bash

install_nomad() {

cd /tmp
curl --silent --remote-name https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip
unzip nomad_${nomad_version}_linux_amd64.zip
chown root:root nomad
mv nomad /usr/local/bin/


echo "--> Writing configuration"
sudo mkdir -p ${data_dir}
sudo mkdir -p /etc/nomad.d
sudo echo ${nomad_lic} > ${data_dir}/license.hclic
sudo tee /etc/nomad.d/config.hcl > /dev/null <<EOF
name            = "${node_name}"
data_dir        = "${data_dir}"
enable_debug    = true
bind_addr       = "${bind_addr}"
datacenter      = "${datacenter}"
region          = "${region}"
enable_syslog   = "true"
advertise {
  http = "$(private_ip):4646"
  rpc  = "$(private_ip):4647"
  serf = "$(private_ip):4648"
}
server {
  enabled          = ${server}
  bootstrap_expect = ${server_count}
  license_path     = "${data_dir}/license.hclic"
  server_join {
    retry_join = ["provider=aws tag_key=nomad_join tag_value=${nomad_join}"]
  }
}

acl {
  enabled = true
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}
autopilot {
    cleanup_dead_servers = true
    last_contact_threshold = "200ms"
    max_trailing_logs = 250
    server_stabilization_time = "10s"
    enable_redundancy_zones = false
    disable_upgrade_migration = false
    enable_custom_upgrades = false
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/nomad.sh > /dev/null <<"EOF"
export NOMAD_ADDR="http://${node_name}.node.consul:4646"
EOF
source /etc/profile.d/nomad.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad Server
Documentation=https://www.nomadproject.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
ExecStart=/usr/local/bin/nomad agent -config="/etc/nomad.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

echo "--> Starting nomad"
sudo systemctl enable nomad
sudo systemctl start nomad
sleep 2

echo "--> Waiting for all Nomad servers"
while [ "$(nomad server members 2>&1 | grep "alive" | wc -l)" -lt "${server_count}" ]; do
  sleep 5
done

echo "--> Waiting for Nomad leader"
while [ -z "$(curl -s http://localhost:4646/v1/status/leader)" ]; do
  sleep 5
done

echo "==> Nomad Server is Installed!"

}

install_nomad