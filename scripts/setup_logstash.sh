#!/usr/bin/env sh

set -euo pipefail

cp -r config/. /logstash_config
cp -r data/. /logstash_data
cp -r pipeline/. /logstash_pipeline
cp -r /pwd/config.skel/logstash/. /logstash_config
mv /logstash_config/pipeline/* /logstash_pipeline
rm -r /logstash_config/pipeline

rm -r config data pipeline
ln -s /logstash_config config
ln -s /logstash_data data
ln -s /logstash_pipeline pipeline
ln -s /certs config/certs

chown -R 1000 /logstash_config
chown -R 1000 /logstash_data
chown -R 1000 /logstash_pipeline

su logstash <<SU
yes | bin/logstash-keystore create
bin/logstash-keystore add "LOGSTASH_SYSTEM_PASSWORD" -x < /passwords/logstash_system
SU

unlink config/certs
