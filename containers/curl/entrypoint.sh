#!/usr/bin/env sh

ELASTIC_PASSWORD=$(cat /passwords/elastic)
curl \
    --silent \
    --show-error \
    --cacert /certs/ca/ca.crt \
    --request ${METHOD} \
    --user elastic:${ELASTIC_PASSWORD} \
    https://elasticsearch:9200/${URL} |
    ([ ${JQ} != true ] && cat || jq)
