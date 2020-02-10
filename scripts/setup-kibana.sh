#!/usr/bin/env sh

set -euo pipefail

chown -R 1000 /usr/share/kibana/config
chown -R 1000 /usr/share/kibana/data

echo
echo "-------------------------------------------------------------------------------"
echo "Storing kibana password..."
echo "-------------------------------------------------------------------------------"
su kibana <<SU
bin/kibana-keystore create
bin/kibana-keystore add "elasticsearch.password" -x < /passwords/kibana
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.security.encryptionKey" -x
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.encrypted_saved_objects.encryptionKey" -x
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.reporting.encryptionKey" -x
SU
