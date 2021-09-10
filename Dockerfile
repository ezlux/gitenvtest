FROM alpine:3.13 


RUN apk add  vim
COPY .env /usr/share/

STOPSIGNAL SIGTERM

# Build-time metadata as defined at http://label-schema.org
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF 
