ARG DOCKER_VER=18.04.0-ce

FROM docker:${DOCKER_VER}

ARG VCS_REF
ARG DOCKER_VER

LABEL maintainer="Spritsail <docker-plugin@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="docker-build" \
      org.label-schema.description="A Drone CI plugin for building and labelling Docker images" \
      org.label-schema.version=${VCS_REF} \
      io.spritsail.version.docker=${DOCKER_VER}

ADD *.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.sh

ENTRYPOINT [ "/usr/local/bin/build.sh" ]
