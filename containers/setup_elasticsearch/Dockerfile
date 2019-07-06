ARG tag
FROM docker.elastic.co/elasticsearch/elasticsearch:${tag}

RUN yum install -y unzip && \
    yum clean all

ADD entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
