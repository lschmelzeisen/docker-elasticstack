BASENAME=$(shell basename ${PWD})

# Arguments for 'make curl'
METHOD=GET
URL=''
JQ=true

# Arguments for 'make logs-*'
LOGS='.message'

# Arguments for 'make password'
USER='elastic'

start: .installed
	docker-compose run --rm start
.PHONY: start

stop:
	docker-compose stop
.PHONY: stop

.installed:
	docker-compose pull
	docker-compose run --rm setup_elasticsearch
	docker-compose run --rm setup_kibana
	docker-compose run --rm setup_logstash
	touch .installed

clean:
	docker-compose down -v
	rm -f .installed
.PHONY: clean

clean-elasticsearch:
	docker-compose rm -sf elasticsearch
	docker volume rm -f ${BASENAME}_elasticsearch_config ${BASENAME}_elasticsearch_data
.PHONY: clean-elasticsearch

clean-kibana:
	docker-compose rm -sf kibana
	docker volume rm -f ${BASENAME}_kibana_config ${BASENAME}_kibana_data
.PHONY: clean-kibana

clean-logstash:
	docker-compose rm -sf logstash
	docker volume rm -f ${BASENAME}_logstash_config ${BASENAME}_logstash_data ${BASENAME}_logstash_pipeline
.PHONY: clean-logstash

logs-elasticsearch:
	@docker-compose logs --no-color elasticsearch | tail -n +3 | sed "s/^[^|]* | //g" | jq ${LOGS}
.PHONY: logs-elasticsearch

logs-kibana:
	@docker-compose logs --no-color kibana | tail -n +2 | sed "s/^[^|]* | //g" | jq ${LOGS}
.PHONY: logs-elasticsearch

logs-logstash:
	@docker-compose logs --no-color logstash | tail -n +2 | sed "s/^[^|]* | //g"
.PHONY: logs-logstash

volume-helper:
	@docker-compose run --rm volume_helper
.PHONY: volume-helper

ca-cert:
	$(eval TEMPFILE := $(shell mktemp elasticstack.XXXXXXXXXX))
	@docker-compose up --no-start volume_helper > /dev/null 2>&1
	@docker cp $$(docker-compose ps -q volume_helper):/certs/ca/ca.crt ${TEMPFILE}
	@cat ${TEMPFILE}
	@docker-compose rm -f volume_helper > /dev/null 2>&1
	@rm ${TEMPFILE}
.PHONY: ca-cert

password:
	$(eval TEMPFILE := $(shell mktemp elasticstack.XXXXXXXXXX))
	@docker-compose up --no-start volume_helper > /dev/null 2>&1
	@docker cp $$(docker-compose ps -q volume_helper):/passwords/${USER} ${TEMPFILE}
	@cat ${TEMPFILE}
	@docker-compose rm -f volume_helper > /dev/null 2>&1
	@rm ${TEMPFILE}
.PHONY: password-elasticsearch

curl:
	@docker-compose run --rm -e METHOD=${METHOD} -e URL=${URL} -e JQ=${JQ} curl
.PHONY: health

health:
	@docker-compose run --rm -e METHOD=GET -e URL=_cat/health -e JQ=false curl
.PHONY: health
