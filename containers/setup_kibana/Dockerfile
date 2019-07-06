ARG tag
FROM docker.elastic.co/kibana/kibana:${tag}

USER 0

ADD entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
