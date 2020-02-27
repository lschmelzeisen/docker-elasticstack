#!/usr/bin/env python3

# This example script uses "localhost" as the host to connect to and reads all
# other parameters (port, auto-generated password and certificate) from the
# cluster. Naturally, this only works if the cluster was started on the same
# machine as your are running this script from. It should be straight-forward
# to adapt the existing parameters to connect from other machines.

from pathlib import Path
from pprint import pprint

from elasticsearch import Elasticsearch


def make_connection(host, port, user, password, ca_cert):
    return Elasticsearch(
        hosts=host,
        http_auth=(user, password),
        scheme="https",
        port=port,
        use_ssl=True,
        ssl_show_warn=True,
        ssl_assert_hostname=host,
        verify_certs=True,
        ca_certs=ca_cert,
    )


def fetch_connection_parameters():
    repo_dir = Path(__file__).resolve().parent.parent.parent
    dotenv = read_dotenv_file(repo_dir / ".env")
    stack_dir = repo_dir / dotenv["STACK_DIR"]

    host = "localhost"
    port = int(dotenv["ELASTICSEARCH_PORT"])
    user = "elastic"
    password = (stack_dir / "passwords" / "elastic").read_text()
    ca_cert = stack_dir / "certs" / "ca" / "ca.crt"

    return host, port, user, password, ca_cert


def read_dotenv_file(dotenv_file):
    dotenv = {}
    with dotenv_file.open("r", encoding="UTF-8") as fin:
        for line in fin:
            if line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            dotenv[key.strip()] = value.strip()
    return dotenv


if __name__ == "__main__":
    host, port, user, password, ca_cert = fetch_connection_parameters()
    elasticsearch = make_connection(host, port, user, password, ca_cert)

    print("Cluster Info:")
    pprint(elasticsearch.info())
    print()
    print("Cluster Health:")
    pprint(elasticsearch.cluster.health())
