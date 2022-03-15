FROM library/ubuntu:20.04@sha256:8ae9bafbb64f63a50caab98fd3a5e37b3eb837a3e0780b78e5218e63193961f9

ARG VERSION=latest

ENV DEBIAN_FRONTEND="noninteractive"

RUN set -e \
	&& apt-get -y update \
	&& apt-get -y install \
		curl \
		jq \
		wget
COPY install-gh-cli.sh .
RUN set -e \
	&& sh install-gh-cli.sh "${VERSION}" \
	&& rm install-gh-cli.sh \
	&& rm -f '/tmp/gh-cli.deb' \
	&& rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["gh"]
