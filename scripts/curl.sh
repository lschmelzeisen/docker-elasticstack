#!/usr/bin/env sh

set -euo pipefail

curl \
    --silent \
    --show-error \
    --cacert /certs/ca/ca.crt \
    --user elastic:$(cat /passwords/elastic) \
    --request GET \
    https://elasticsearch:9200/${URL} \
    ${CURL_OPTS}
