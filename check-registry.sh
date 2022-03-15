#!/bin/sh
set -e
error() { echo "error: $*" >&2; }
die() { echo "error: $*" >&2; exit 1; }
count() { 'def count(s): reduce s as $_ (0;.+1); count(.[])'; }
usage()
{
	if test "$#" -gt '0'; then
		error "${*}"
		echo "try '${0} --help'" >&2
		exit 1
	fi


	sed -e 's/^	//'<<END_OF_USAGE
	usage ${0} [options] namespace/repository/tag
	options:

END_OF_USAGE
	# requests for help are never an error
	exit 0
}

USERNAME=
AUTH_TOKEN=
REGISTRY='docker.io'
while test "$#" -gt '0'; do
	case "${1}" in
	(-U|--user)		USERNAME="${2}";shift;;
	(-A|--auth-token)	AUTH_TOKEN="${2}";shift;;
	(-R|--registry)		REGISTRY="${2}"; shift;;

	# Basic getopt handling
	(-h|--help)		usage;;
	(--)			shift; break;;
	(-*)			usage "unknown option '${1}'";;
	(*)			break;;
	esac
	shift
done

test "$#" -gt '0' || die 'nothing to check'

# Docker's API endpoints are sort of a mess
if test "${REGISTRY}" = 'docker.io'; then
	REGISTRY='hub.docker.com'
fi
namespace="${1%%/*}"
repository="${1#*/}"
tag="${repository#*/}"
repository="${repository%%/*}"
: "namespace=${namespace}", "repository=${repository}", "tag=${tag}"

set --
if test -n "${AUTH_TOKEN}"; then
	test -n "${USERNAME}" || usage 'no username specified'
fi
if test -n "${USERNAME}"; then
	test -n "${AUTH_TOKEN}" || usage 'no auth token specified'
	token="$(curl -sL -u "${USERNAME}:${AUTH_TOKEN}" "https://${REGISTRY}/token?service=${REGISTRY}&scope=repository:${namespace}/${repository}:pull&client_id=action")"
	test -z "${AUTH_TOKEN}" || set -- -H "Authorization: Bearer $(printf '%s' "${token}" | jq -r '.token')"
fi

case "${REGISTRY}" in
(hub.docker.com)
	# use unathenticated endpoint for Docker hub
	set -- "${@}" "https://hub.docker.com/v2/repositories/${namespace}/${repository}/tags/${tag}/";;

(*)
	set -- "${@}" "https://${REGISTRY}/v2/${namespace}/${repository}/manifests/${tag}";;
esac

exec curl --fail -sL "${@}" > /dev/null
