#!/usr/bin/env sh

ELASTIC_PASSWORD=$(cat /run/secrets/elastic_password | grep -o "\w\+")
curl -s --cacert /run/secrets/ca.crt -u elastic:${ELASTIC_PASSWORD} https://es01:9200/${URL} |
    ([ ${JQ} != true ] && cat || jq)
