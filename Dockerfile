FROM docker:latest

LABEL maintainer="<docker-plugin@spritsail.io>"

ADD *.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.sh

ENTRYPOINT [ "/usr/local/bin/build.sh" ]
