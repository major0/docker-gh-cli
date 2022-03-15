#!/bin/sh
set -e

cleanup() {
	rm -f '/tmp/gh-cli.deb' \
	rm -rf /var/lib/apt/lists/*
}
jq_release_query="$(printf '.[] | select( .tag_name == "%s" ) | .id' "${1}")"
jq_download_query='.assets[] | select(.browser_download_url | contains("linux_amd64.deb")) | .browser_download_url'
RELEASE_ID="$(curl -s "https://api.github.com/repos/cli/cli/releases" | jq -r "${jq_release_query}")"
RELEASE_URL="$(curl -s "https://api.github.com/repos/cli/cli/releases/$RELEASE_ID" | jq -r "${jq_download_query}")"
trap cleanup EXIT
wget -O '/tmp/gh-cli.deb' "${RELEASE_URL}"
apt-get -y install '/tmp/gh-cli.deb'
