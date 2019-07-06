FROM docker.elastic.co/elasticsearch/elasticsearch:7.2.0

RUN yum install -y unzip && \
    yum clean all

ADD entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
