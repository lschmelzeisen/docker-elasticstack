BASENAME=$(shell basename ${PWD})

# Arguments for 'make curl'
METHOD=GET
URL=''
JQ=true

# Arguments for 'make logs-*'
LOGS='.message'

start: .installed
	docker-compose run --rm start
.PHONY: start

stop:
	docker-compose stop
.PHONY: stop

.installed:
	docker-compose run --rm setup_elasticsearch
	docker-compose run --rm setup_kibana
	touch .installed

clean:
	docker-compose down -v
	rm -f .installed
.PHONY: clean

clean-elasticsearch:
	docker-compose rm -sf elasticsearch
	docker volume rm ${BASENAME}_elasticsearch_config ${BASENAME}_elasticsearch_data
.PHONY: clean-elasticsearch

clean-kibana:
	docker-compose rm -sf kibana
	docker volume rm ${BASENAME}_kibana_config ${BASENAME}_kibana_data
.PHONY: clean-kibana

logs-elasticsearch:
	docker-compose logs --no-color elasticsearch | tail -n +3 | cut -d"|" -f2- | jq ${LOGS}
.PHONY: logs-elasticsearch

logs-kibana:
	docker-compose logs --no-color kibana | tail -n +2 | cut -d"|" -f2- | jq ${LOGS}
.PHONY: logs-elasticsearch

ca-cert:
	$(eval TEMPFILE := $(shell mktemp elasticstack.XXXXXXXXXX))
	@docker-compose up --no-start volume_helper > /dev/null 2>&1
	@docker cp $$(docker-compose ps -q volume_helper):/certs/ca/ca.crt ${TEMPFILE}
	@cat ${TEMPFILE}
	@docker-compose rm -f volume_helper > /dev/null 2>&1
	@rm ${TEMPFILE}
.PHONY: ca-cert

password-elastic:
	$(eval TEMPFILE := $(shell mktemp elasticstack.XXXXXXXXXX))
	@docker-compose up --no-start volume_helper > /dev/null 2>&1
	@docker cp $$(docker-compose ps -q volume_helper):/passwords/elastic ${TEMPFILE}
	@cat ${TEMPFILE}
	@docker-compose rm -f volume_helper > /dev/null 2>&1
	@rm ${TEMPFILE}
.PHONY: password-elasticsearch

password-kibana:
	$(eval TEMPFILE := $(shell mktemp elasticstack.XXXXXXXXXX))
	@docker-compose up --no-start volume_helper > /dev/null 2>&1
	@docker cp $$(docker-compose ps -q volume_helper):/passwords/kibana ${TEMPFILE}
	@cat ${TEMPFILE}
	@docker-compose rm -f volume_helper > /dev/null 2>&1
	@rm ${TEMPFILE}
.PHONY: password-elasticsearch

curl:
	docker-compose run --rm -e METHOD=${METHOD} -e URL=${URL} -e JQ=${JQ} curl
.PHONY: health

health:
	docker-compose run --rm -e METHOD=GET -e URL=_cat/health -e JQ=false curl
.PHONY: health
