#!/usr/bin/env sh

set -euo pipefail

ELASTIC_PASSWORD=$(cat /passwords/elastic)
curl \
    --silent \
    --show-error \
    --cacert /certs/ca/ca.crt \
    --user elastic:${ELASTIC_PASSWORD} \
    --request GET \
    https://elasticsearch:9200/${URL} \
    ${CURL_OPTS} |
    ([ ${JQ} != true ] && cat || jq)
