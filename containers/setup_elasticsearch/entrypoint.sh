#!/usr/bin/env sh

set -euo pipefail

cp -r config/. /elasticsearch_config
cp -r data/. /elasticsearch_data
cp -r /pwd/config.skel/elasticsearch/. /elasticsearch_config/

rm -r config data
ln -s /elasticsearch_config config
ln -s /elasticsearch_data data
ln -s /certs config/certs

echo "Auto-generating certificates..."
bin/elasticsearch-certutil cert --silent --pem --in /pwd/config.skel/instances.yml --out /certs/bundle.zip
unzip /certs/bundle.zip -d /certs/
rm /certs/bundle.zip

chown -R 1000 /elasticsearch_config
chown -R 1000 /elasticsearch_data
chown -R 1000 /certs
chown -R 1000 /passwords

echo "Starting Elasticsearch..."
/usr/local/bin/docker-entrypoint.sh &

echo "Waiting for Elasticsearch to start..."
while ! nc -z localhost 9200; do
    sleep 1
done

echo "Auto-generating passwords..."
bin/elasticsearch-setup-passwords auto --batch --url https://localhost:9200 |
    while read line; do
        if grep -q "PASSWORD" <<< $line; then
            read user password <<< $(sed "s/^PASSWORD \(\w\+\) = \(\w\+\)$/\1 \2/" <<< $line)
            printf %s "${password}" > /passwords/${user}
        fi
    done

pkill -SIGTERM java
echo "Waiting for Elasticsearch to shutdown..."
while pkill -0 java; do
    sleep 1
done

unlink config/certs
