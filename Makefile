include .env

PROJECT_NAME=$(shell basename ${PWD})

# Arguments for "make curl"
URL=""

# ------------------------------------------------------------------------------

# See: https://blog.thapaliya.com/posts/well-documented-makefiles/
help: ##- Show this help message.
	@awk 'BEGIN {FS = ":.*##-"; printf "usage: make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##-/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
.PHONY: help

# ------------------------------------------------------------------------------

start: .setup ##- Start the cluster (perform any setup if necessary).
	podman-compose up -d
.PHONY: up

stop: ##- Stop the cluster.
	podman-compose down
.PHONY: down

clean: stop ##- Remove all created files (this deletes all your data!).
	rm -rf ${STACK_DIR}/* .setup
.PHONY: clean-new

# ------------------------------------------------------------------------------

# Sometimes, when you get Elasticsearch has problems starting, it will fail to
# populate the logs with correct JSON-format. In those cases you can manually
# check the complete logs via `podman-compose logs elasticsearch`.
#
# The `jq -R -r '. as $line | try fromjson catch $line'` pattern is taken from
# https://github.com/stedolan/jq/issues/884#issuecomment-338326479

logs-elasticsearch: ##- Print message of JSON-logs of Elasticsearch.
	@podman-compose logs elasticsearch | jq -R -r '. as $$line | try (fromjson | "\(.timestamp) | \(.level) | \(.message)") catch $$line'
.PHONY: logs-elasticsearch

logs-kibana: ##- Print message of JSON-logs of Kibana.
	@podman-compose logs kibana | jq -R -r '. as $$line | try (fromjson | "\(.["@timestamp"]) | \((.tags[0] // "null") | ascii_upcase) | \(.message)") catch $$line'
.PHONY: logs-kibana

# ------------------------------------------------------------------------------

health: ##- Check health status of cluster.
	@make --silent curl URL="_cat/health"
.PHONY: health

curl: ##- Send TLS-encrypted curl-requests cluster.
	@curl \
		--silent \
		--show-error \
		--cacert "${STACK_DIR}/certs/ca/ca.crt" \
		--user elastic:`cat "${STACK_DIR}/passwords/elastic"` \
		--request GET \
		"https://localhost:${ELASTICSEARCH_PORT}/${URL}"
.PHONY: curl

# ------------------------------------------------------------------------------

# Used to setup certs and passwords.

.setup:
	mkdir -p ${STACK_DIR}/certs ${STACK_DIR}/passwords
	mkdir -p ${STACK_DIR}/config-elasticsearch ${STACK_DIR}/logs-elasticsearch ${STACK_DIR}/data-elasticsearch
	cp -r ./config-elasticsearch/* ${STACK_DIR}/config-elasticsearch
	mkdir -p ${STACK_DIR}/config-kibana ${STACK_DIR}/data-kibana
	cp -r ./config-kibana/* ${STACK_DIR}/config-kibana
	make setup-elasticsearch setup-kibana
	podman-compose -f docker-compose.setup.yml down
	touch .setup

setup-elasticsearch:
	podman-compose -f docker-compose.setup.yml run --rm elasticsearch
.PHONY: setup-elasticsearch

setup-kibana:
	podman-compose -f docker-compose.setup.yml run --rm kibana
.PHONY: setup-kibana

# ------------------------------------------------------------------------------

# Reset config-* directories to Elasticsearch/Kibana defaults. These are only
# helpers for the development of this repo. As a user you should ignore them.

config: config-elasticsearch config-kibana
.PHONY: config

config-elasticsearch:
	podman create --name ${PROJECT_NAME}_elasticsearch-config docker.elastic.co/elasticsearch/elasticsearch:${TAG}
	podman cp ${PROJECT_NAME}_elasticsearch-config:/usr/share/elasticsearch/config ./config-elasticsearch
	podman rm -f ${PROJECT_NAME}_elasticsearch-config

config-kibana:
	podman create --name ${PROJECT_NAME}_kibana-config docker.elastic.co/kibana/kibana:${TAG}
	podman cp ${PROJECT_NAME}_kibana-config:/usr/share/kibana/config/. ./config-kibana
	podman rm -f ${PROJECT_NAME}_kibana-config
