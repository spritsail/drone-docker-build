FROM docker:latest

ARG VCS_REF

LABEL maintainer="Spritsail <docker-plugin@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="docker-build" \
      org.label-schema.description="A Drone CI plugin for building and labelling Docker images" \
      org.label-schema.version=${VCS_REF}

ADD *.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.sh

ENTRYPOINT [ "/usr/local/bin/build.sh" ]
