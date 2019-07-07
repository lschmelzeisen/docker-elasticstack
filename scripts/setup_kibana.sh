#!/usr/bin/env sh

set -euo pipefail

cp -r config/. /kibana_config
cp -r data/. /kibana_data
cp -r /pwd/config.skel/kibana/. /kibana_config

rm -r config data
ln -s /kibana_config config
ln -s /kibana_data data
ln -s /certs config/certs

chown -R 1000 /kibana_config
chown -R 1000 /kibana_data

su kibana <<SU
bin/kibana-keystore create
bin/kibana-keystore add "elasticsearch.password" -x < /passwords/kibana
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.security.encryptionKey" -x
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.encrypted_saved_objects.encryptionKey" -x
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.reporting.encryptionKey" -x
SU

unlink config/certs
