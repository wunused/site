FROM ubuntu:20.04

RUN apt-get update && apt-get install -y hugo

WORKDIR /site

COPY . /site

CMD hugo server --bind="0.0.0.0"
