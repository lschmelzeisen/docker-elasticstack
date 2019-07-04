include .env

# Arguments for 'make query'
URL=''
JQ=true

start: setup
	docker-compose run --rm start
.PHONY: start

stop:
	docker-compose stop
.PHONY: stop

setup:
	if [ ! -f .installed ]; then \
		mkdir data; \
		mkdir data/es01; \
		\
		mkdir .certs; \
		mkdir .passwords; \
		\
		docker-compose run --rm create-certs; \
		docker-compose run --rm start; \
		\
		docker-compose exec es01 /bin/bash -c "\
			bin/elasticsearch-setup-passwords auto \
				--batch \
				-E xpack.security.http.ssl.certificate=certs/es01.crt \
				-E xpack.security.http.ssl.certificate_authorities=certs/ca.crt \
				-E xpack.security.http.ssl.key=certs/es01.key \
				--url https://localhost:9200" | scripts/parse_passwords.sh; \
		\
		touch .installed; \
	fi
.PHONY: install

clean:
	docker-compose down -v
	rm -rf .certs
	rm -rf .passwords
	rm -f .installed
.PHONY: clean

clean-data: clean
	rm -rf data
.PHONY: clean-data

query:
	docker-compose run --rm -e URL=${URL} -e JQ=${JQ} query
.PHONY: health

health:
	docker-compose run --rm -e URL=_cat/health -e JQ=false query
.PHONY: health
