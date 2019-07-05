# Arguments for 'make curl'
METHOD=GET
URL=''
JQ=true

start: .installed
	docker-compose run --rm start
.PHONY: start

stop:
	docker-compose stop
.PHONY: stop

.installed:
	docker-compose run --rm setup
	touch .installed

clean:
	docker-compose down -v
	rm -f .installed
.PHONY: clean

curl:
	docker-compose run --rm -e METHOD=${METHOD} -e URL=${URL} -e JQ=${JQ} curl
.PHONY: health

health:
	docker-compose run --rm -e METHOD=GET -e URL=_cat/health -e JQ=false curl
.PHONY: health

logs-elasticsearch:
	docker-compose logs | tail -n +3 | cut -c 29- | jq .message
.PHONY: logs-elasticsearch
