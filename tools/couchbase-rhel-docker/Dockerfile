#FROM centos:6
# This is a RHEL 7 image from Redhat
FROM registry.access.redhat.com/rhel7

MAINTAINER Couchbase Docker Team <docker@couchbase.com>

# build-time args for RH subscription
ARG RH_USER
ARG RH_PASSWORD

RUN echo $RH_USER $RH_PASSWORD

RUN subscription-manager register --username $RH_USER --password $RH_PASSWORD --auto-attach

# Update server
RUN yum -y update; yum clean all

# Install utils and dependencies
RUN yum install -y tar \
    && yum clean all && \
      yum -y install openssl \
      lsof lshw net-tools numactl \
      sysstat wget screen psmisc \
      zip unzip

# Install python-httplib2
RUN curl https://bootstrap.pypa.io/get-pip.py | python - ; pip install httplib2

COPY functions /etc/init.d/

ENV CB_VERSION=4.5.1 \
    CB_RELEASE_URL=http://packages.couchbase.com/releases \
    CB_PACKAGE=couchbase-server-enterprise-4.5.1-centos7.x86_64.rpm \
    PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Install couchbase
RUN rpm --install $CB_RELEASE_URL/$CB_VERSION/$CB_PACKAGE

#clean the cache
RUN yum clean all

# install dumb-init (to handle signals properly)
RUN curl -sL https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 > /usr/local/bin/dumb-init && \
    echo "81231da1cd074fdc81af62789fead8641ef3f24b6b07366a1c34e5b059faf363  /usr/local/bin/dumb-init" | sha256sum -c && \
    chmod +x /usr/local/bin/dumb-init

COPY scripts/couchbase-start /usr/local/bin/

RUN chgrp -R 0 /opt/couchbase/var && \
    chmod -R g+rw /opt/couchbase/var && \
    find /opt/couchbase/var -type d -exec chmod g+x {} +

VOLUME /opt/couchbase/var

LABEL Name=rhel7/couchbase-server
LABEL Release=Latest 
LABEL Vendor=Couchbase 
LABEL Version=4.5.1 
LABEL Architecture="x86_64"
LABEL RUN="docker run -d --rm --privileged -p 8091:8091 --restart always --name NAME IMAGE \
            -v /opt/couchbase/var:/opt/couchbase/var \
            -v /opt/couchbase/var/lib/moxi:/opt/couchbase/var/lib/moxi \
            -v /opt/couchbase/var/lib/stats:/opt/couchbase/var/lib/stats "

USER 184

ENTRYPOINT ["dumb-init", "couchbase-start"]
CMD ["couchbase-server", "--", "-kernel", "global_enable_tracing", "false", "-noinput"]
# pass -noinput so it doesn't drop us in the erlang shell

# 8091: Couchbase Web console, REST/HTTP interface
# 8092: Views, queries, XDCR
# 8093: Query services (4.0+)
# 8094: Full-text Serarch (4.5+)
# 11207: Smart client library data node access (SSL)
# 11210: Smart client library/moxi data node access
# 11211: Legacy non-smart client library data node access
# 18091: Couchbase Web console, REST/HTTP interface (SSL)
# 18092: Views, query, XDCR (SSL)
# 18093: Query services (SSL) (4.0+)
EXPOSE 8091 8092 8093 8094 11207 11210 11211 18091 18092 18093
