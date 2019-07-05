# Arguments for 'make curl'
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
	docker-compose run --rm -e URL=${URL} -e JQ=${JQ} curl
.PHONY: health

health:
	docker-compose run --rm -e URL=_cat/health -e JQ=false curl
.PHONY: health
