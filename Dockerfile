FROM alpine:latest
MAINTAINER "Falk Reimann <falk.rei@gmail.com>"

ADD build/docker.tar /usr/bin/
ENTRYPOINT ["/usr/bin/uddns_linux_amd64"]
