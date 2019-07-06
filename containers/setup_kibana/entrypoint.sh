#!/usr/bin/env sh

cp -r config/. /kibana_config
cp -r data/. /kibana_data
cp -r /pwd/config.skel/kibana/. /kibana_config

cat <<YML >>/kibana_config/kibana.yml
xpack.security.encryptionKey: "$(tr -dc [:alnum:] < /dev/urandom | head -c 32)"
xpack.encrypted_saved_objects.encryptionKey: "$(tr -dc [:alnum:] < /dev/urandom | head -c 32)"
xpack.reporting.encryptionKey: "$(tr -dc [:alnum:] < /dev/urandom | head -c 32)"
YML

rm -r config data
ln -s /kibana_config config
ln -s /kibana_data data
ln -s /certs config/certs

chown -R 1000 /kibana_config
chown -R 1000 /kibana_data

su kibana <<SU
bin/kibana-keystore create
bin/kibana-keystore add "elasticsearch.password" -x < /passwords/kibana
SU

unlink config/certs
