#!/usr/bin/env sh

set -euo pipefail

chown -R 1000 /usr/share/kibana/config
chown -R 1000 /var/data/kibana

echo
echo "-------------------------------------------------------------------------------"
echo "Storing kibana password..."
echo "-------------------------------------------------------------------------------"
su kibana <<SU
# See: https://www.elastic.co/guide/en/elasticsearch/reference/current/get-started-kibana-user.html
bin/kibana-keystore create
bin/kibana-keystore add "elasticsearch.password" -x < /passwords/kibana

# See: https://www.elastic.co/guide/en/kibana/current/using-kibana-with-security.html#using-kibana-with-security
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.encryptedSavedObjects.encryptionKey" -x || true
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.security.encryptionKey" -x || true
tr -dc [:alnum:] < /dev/urandom | head -c 32 | bin/kibana-keystore add "xpack.reporting.encryptionKey" -x || true

# bin/kibana-keystore doesn't obey path.data configuration, so need to copy
# to that directory manually.
cp /usr/share/kibana/data/kibana.keystore /var/data/kibana/kibana.keystore
SU
