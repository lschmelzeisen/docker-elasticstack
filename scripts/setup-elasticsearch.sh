#!/usr/bin/env sh

set -euo pipefail

echo
echo "-------------------------------------------------------------------------------"
echo "Installing dependencies..."
echo "-------------------------------------------------------------------------------"
yum install -y unzip

echo
echo "-------------------------------------------------------------------------------"
echo "Auto-generating certificates..."
echo "-------------------------------------------------------------------------------"
# See: https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html
bin/elasticsearch-certutil cert --silent --pem --in /instances.yml --out /usr/share/elasticsearch/config/certs/bundle.zip
unzip /usr/share/elasticsearch/config/certs/bundle.zip -d /usr/share/elasticsearch/config/certs/
rm /usr/share/elasticsearch/config/certs/bundle.zip

chown -R 1000 /usr/share/elasticsearch/config
chown -R 1000 /usr/share/elasticsearch/config/certs
chown -R 1000 /var/log/elasticsearch
chown -R 1000 /var/data/elasticsearch
chown -R 1000 /passwords

echo
echo "-------------------------------------------------------------------------------"
echo "Starting Elasticsearch..."
echo "-------------------------------------------------------------------------------"
/usr/local/bin/docker-entrypoint.sh &

echo
echo "-------------------------------------------------------------------------------"
echo "Waiting for Elasticsearch to start..."
echo "-------------------------------------------------------------------------------"
while ! nc -z localhost 9200 ; do
    sleep 1
done

echo
echo "-------------------------------------------------------------------------------"
echo "Auto-generating passwords for built-in users..."
echo "-------------------------------------------------------------------------------"
# See: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-passwords.html
bin/elasticsearch-setup-passwords auto --batch --url https://localhost:9200 |
    while read line ; do
        if grep -q "PASSWORD" <<< $line; then
            read user password <<< $(sed "s/^PASSWORD \(\w\+\) = \(\w\+\)$/\1 \2/" <<< $line)
            printf %s "${password}" > /passwords/${user}
        fi
    done

echo
echo "-------------------------------------------------------------------------------"
echo "Waiting for Elasticsearch to shutdown..."
echo "-------------------------------------------------------------------------------"
pkill -SIGTERM java
while pkill -0 java; do
    sleep 1
done
