#!/usr/bin/env sh

ELASTIC_PASSWORD=$(cat /passwords/elastic)
curl -s --cacert /certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} https://elasticsearch:9200/${URL} |
    ([ ${JQ} != true ] && cat || jq)
