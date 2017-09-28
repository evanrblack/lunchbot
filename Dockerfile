FROM ruby:alpine

ADD . /lunchbot
WORKDIR /lunchbot

ENV BUILD_PACKAGES \
  gcc \
  libc-dev \
  libffi-dev \
  make \
  sqlite-dev
ENV RUNTIME_PACKAGES \
  sqlite-libs \
  tzdata

RUN set -ex \
  && apk add --no-cache --virtual .build-packages $BUILD_PACKAGES \
  && apk add --no-cache $RUNTIME_PACKAGES \
  && bundle install --jobs 4 \
  && apk del .build-packages

EXPOSE 9292
