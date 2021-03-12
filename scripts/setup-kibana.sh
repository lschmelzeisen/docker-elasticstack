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
bin/kibana-keystore add "elasticsearch.username" -x < <(echo "kibana_system")
bin/kibana-keystore add "elasticsearch.password" -x < /passwords/kibana_system

# See: https://www.elastic.co/guide/en/kibana/current/using-kibana-with-security.html#using-kibana-with-security
echo -e "\n# Encrpytion Keys" >> /usr/share/kibana/config/kibana.yml
bin/kibana-encryption-keys generate | tail -n 4 >> /usr/share/kibana/config/kibana.yml

# bin/kibana-keystore doesn't obey copy to the config directory yet.
cp /usr/share/kibana/data/kibana.keystore /usr/share/kibana/config/kibana.keystore
SU
