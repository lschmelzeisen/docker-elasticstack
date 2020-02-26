# docker-elasticstack

Setup of [Elasticsearch](https://www.elastic.co/elasticsearch) and
[Kibana](https://www.elastic.co/kibana) based on Docker that

* runs only a single node,
* follows recommendations for a production-ready cluster, and
* keeps configuration straightforward and well-documented.

At least to the degree that this is possible.

Of course the above comes with with a huge caveat: running only a single node
means no redudancy and no data replication.
Thus you should only use this if in your use case hardware/software failures are
not critical; that is where downtime and data loss is tolerable.

What then is offered in terms of being ready for production?

* Runs exactly the [Docker images released by Elastic](https://www.docker.elastic.co/).
* Set system and container settings as recommended by the [Elasticsearch
  reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/).
* Automatically generates self-signed X.509 certificates during setup and
  [encrypts all communication](https://www.elastic.co/guide/en/elasticsearch/reference/current/configuring-tls.html)
  via TLS of both Elasticsearch and Kibana.
* Uses auto-generated passwords for [builtin users](https://www.elastic.co/guide/en/elasticsearch/reference/current/built-in-users.html)
  and does not store them in plaintext accessible from inside a container.

## Dependencies

A Unix environment with [Make](https://en.wikipedia.org/wiki/Make_(software)) and
the following installed:

* [Docker](https://docs.docker.com/install/)
* [Docker Compose](https://docs.docker.com/compose/install/)

Optional dependencies:

* [jq](https://stedolan.github.io/jq/) for `make logs-*`
* [curl](https://curl.haxx.se/) for `make health` and `make curl`
* [awk](https://en.wikipedia.org/wiki/AWK) for `make help` and `make logs-*`

## Necessary configuration

* Append the following to `/etc/sysctl.conf` (if it exists) or creating a new
  file `/etc/sysctl.d/elasticsearch.conf` to minimize swapping and increase
  number of possible mapped memory areas.
  ```
  vm.swappiness=1 # https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html
  vm.max_map_count=262144 # https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html#vm-max-map-count
  ```
  To apply these settings run `sudo sysctl -p` or restart your system.

* Open `.env` and adjust the settings to your preference.

  The most important setting is `STACK_DIR` which is the path to which all data
  and configuration will be written.
  By default, all data will be written to a subdirectory of this repository.
  (Subdirectories of the `STACK_DIR` are bind-mounted to the containers that use
  them.)

* Edit `instances.yml` and add DNS names and IP addresses under which you will
  want to access your Elasticsearch and Kibana instances (these will be written
  into the generated X.509 certificates and can not easily be changed later).

* Review the Elasticsearch configuration in `config-elasticsearch/`.

  Note that the contents of this directory are only used to bootstrap the
  Elasticsearch configuration, the configuration of the installed cluster
  will reside in `${STACK_DIR}/config-elasticsearch/`.

  You should probably atleast adjust the name of your cluster by changing
  `cluster.name` in `elasticsearch.yml` and the heap size by changing `-Xms`
  and `-Xmx` in `jvm.options` to your needs.

* Review the Kibana configuration in `config-kibana/`.

  Note that the contents of this directory are only used to bootstrap the
  Kibana configuration, the configuration of the installed cluster
  will reside in `${STACK_DIR}/config-kibana/`.

  You don't need to change anything from the defaults.

## Usage

`Makefile`-targets are used to operate the cluster.
See `make help` for descriptions:

```
usage: make <target>

Targets:
  help                Show this help message.
  start               Start the cluster (perform any setup if necessary).
  stop                Stop the cluster.
  clean               Remove all created files (this deletes all your data!).
  logs-elasticsearch  Print message of JSON-logs of Elasticsearch.
  logs-kibana         Print message of JSON-logs of Kibana.
  health              Check health status of cluster.
  curl                Send TLS-encrypted curl-requests cluster.
```

## Common Operations

* **How do I perform setup and start the cluster?**

  Run `make start`.
  Of course the services need a few seconds until everything is available.
  The first time this is executed all necessary setup will automatically be
  executed.
  To stop the running cluster use `make stop`.

* **How can I access Kibana?**

  Via <https://localhost:5601/> for which you substitute the IP or DNS name of
  the server you started the cluster on and the port your configured in `.env`.
  On first access your browser will most likely warn you about an potentially
  unsecure connection.
  This is unavoidable since self-signed certificates are used, just click away
  the warning.
  To log in use the user `elastic` and the generated password from
  `${STACK_DIR}/passwords/elastic`.

* **How can I create new user accounts?**

  To use the default-configured `native` Elasticsearch authentication, just log
  into Kibana and follow the guides to [create users](https://www.elastic.co/guide/en/elasticsearch/reference/current/get-started-users.html)
  and [assign roles](https://www.elastic.co/guide/en/elasticsearch/reference/current/get-started-roles.html).

  The use of other authentication methods (LDAP, Active Directory, PKI, etc.)
  must be manually [configured in the Elasticsearch configuration](https://www.elastic.co/guide/en/elasticsearch/reference/current/get-started-authentication.html).

* **How do I send `curl`-requests?**

  Because TLS-encryption and password-use is required, simple requests like
  `curl localhost:9200/_cat/health` will not recieve a reply.

  Instead you can use the `make curl` helper, like so:

  ```sh
  make curl URL=_cat/health
  ```

  Alternative, because this exact command is often used, it is also available as
  `make health`.

* **How do I adjust my Elasticsearch/Kibana configuration?**

  Stop a potentially running cluster via `make stop`, adjust any configuration
  as desired in the `${STACK_DIR}/config-*` directories,  and restart the
  cluster via `make start`.

* **How do I upgrade to a new Elasticsearch/Kibana version?**

  Stop a potentially running cluster via `make stop`, preferrably backup your
  `${STACK_DIR}` directory, adjust the `TAG` entry in `.env` to the new desired
  version, and restart your cluster via `make start`.

* **Where can I find the generated passwords for the built-in users?**

  These are stored in `${STACK_DIR}/passwords`.

* **Where can I find the generated X.509 certificates?**

  These are stored in `${STACK_DIR}/certs`.
  Specifically, the certificate of the certificate authority (CA) is stored in
  `${STACK_DIR}/certs/ca/ca.crt`.

* **How can I debug problems with the cluster?**

  Elasticsearch and Kibana log message are available via `docker-compose logs
  elasticsearch` and `docker-compose logs kibana`, respectively.
  For example:

  ```
  elasticsearch_1  | {"type": "server", "timestamp": "2020-02-26T10:37:21,752Z", "level": "INFO", "component": "o.e.n.Node", "cluster.name": "docker-elasticstack", "node.name": "elasticsearch", "message": "node name [elasticsearch], node ID [gZ9sFqHGTyujlHoVXfDmsA], cluster name [docker-elasticstack]" }
  ```

  As these JSON message can be quite unreadable you can use the helpers
  `make logs-elasticsearch` and `make logs-kibana` to just view the `message`
  part of the logs.
  For example:

  ```
  2020-02-26T10:37:21,752Z | INFO | node name [elasticsearch], node ID [gZ9sFqHGTyujlHoVXfDmsA], cluster name [docker-elasticstack]
  ```

  However, this only works if actual JSON messages are created.
  For example uncaught Java-exceptions will be printed in plain text to the
  docker logs and not be visible with the above commands.

## Contributing

Please feel free to submit [bug reports](https://github.com/lschmelzeisen/docker-elasticstack/issues) and [pull requests](https://github.com/lschmelzeisen/docker-elasticstack/pulls)!

## License

Copyright 2019-2020 Lukas Schmelzeisen. Licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
