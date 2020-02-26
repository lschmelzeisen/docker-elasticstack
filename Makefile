include .env

PROJECT_NAME=$(shell basename ${PWD})

# Arguments for "make curl"
URL=""

# ------------------------------------------------------------------------------

# See: https://blog.thapaliya.com/posts/well-documented-makefiles/
help: ##- Show this help message.
	@awk 'BEGIN {FS = ":.*#{2}-"; printf "usage: make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?#{2}-/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
.PHONY: help

# ------------------------------------------------------------------------------

start: .setup ##- Start the cluster (perform any setup if necessary).
	docker-compose up -d
.PHONY: up

stop: ##- Stop the cluster.
	docker-compose down
.PHONY: down

clean: stop ##- Remove all created files (this deletes all your data!).
	rm -rf ${STACK_DIR} .setup
.PHONY: clean-new

# ------------------------------------------------------------------------------

# Sometimes, when you get Elasticsearch has problems starting, it will fail to
# populate the logs with correct JSON-format. In those cases you can manually
# check the complete logs via `docker-compose logs elasticsearch`.

logs-elasticsearch: ##- Print message of JSON-logs of Elasticsearch.
	@docker-compose logs --no-color elasticsearch | tail -n +3 | awk 'sub("^[^\\|]* \\| ", "")' | jq -M ".timestamp + \" | \" + .level + \" | \" + .message" | awk 'gsub("\"", "")'
.PHONY: logs-elasticsearch

logs-kibana: ##- Print message of JSON-logs of Kibana.
	@docker-compose logs --no-color kibana | tail -n +3 | awk 'sub("^[^\\|]* \\| ", "")' | jq -M ".[\"@timestamp\"] + \" | \" + .message" | awk 'gsub("\"", "")'
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
	make setup-elasticsearch setup-kibana
	touch .setup

setup-elasticsearch: ${STACK_DIR}
	docker-compose -f docker-compose.helpers.yml run --rm setup-elasticsearch
.PHONY: setup-elasticsearch

setup-kibana: ${STACK_DIR}
	docker-compose -f docker-compose.helpers.yml run --rm setup-kibana
.PHONY: setup-kibana

${STACK_DIR}:
	mkdir ${STACK_DIR}
	mkdir ${STACK_DIR}/certs
	mkdir ${STACK_DIR}/passwords

	cp -r ./config-elasticsearch ${STACK_DIR}/config-elasticsearch
	mkdir ${STACK_DIR}/logs-elasticsearch
	mkdir ${STACK_DIR}/data-elasticsearch

	cp -r ./config-kibana ${STACK_DIR}/config-kibana
	mkdir ${STACK_DIR}/data-kibana

# ------------------------------------------------------------------------------

# Reset config-* directories to Elasticsearch/Kibana defaults. These are only
# helpers for the development of this repo. As a user you should ignore them.

config: config-elasticsearch config-kibana
.PHONY: config

config-elasticsearch:
	docker create --name ${PROJECT_NAME}_elasticsearch-config docker.elastic.co/elasticsearch/elasticsearch:${TAG}
	docker cp ${PROJECT_NAME}_elasticsearch-config:/usr/share/elasticsearch/config ./config-elasticsearch
	docker rm -f ${PROJECT_NAME}_elasticsearch-config

config-kibana:
	docker create --name ${PROJECT_NAME}_kibana-config docker.elastic.co/kibana/kibana:${TAG}
	docker cp ${PROJECT_NAME}_kibana-config:/usr/share/kibana/config/. ./config-kibana
	docker rm -f ${PROJECT_NAME}_kibana-config
