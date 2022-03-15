#!/bin/sh
set -e
error() { echo "error: $*" >&2; }
usage()
{
	if test "$#" -gt '0'; then
		error "$*"
		echo "try '${0} --help'" >&2
		exit 1
	fi

	sed -e 's/^	//'<<END_OF_USAGE
	usage: ${0} [options] <owner>/<repo>
	options:
	  -h, --help			Display this help

END_OF_USAGE

	# requesting help is never an error
	exit 0
}

for arg; do case "${arg}" in (-h|--help) usage;; esac;done
while test "$#" -gt '0'; do
	case "${1}" in
	(-h|--help)		usage;;
	(--)			shift; break;;
	(-*)			usage "unknown option '${1}'";;
	(*)			break;;
	esac
	shift
done

test "$#" -gt '0' || die 'no github package specified'
curl -s "https://api.github.com/repos/${1}/releases" | jq -r '.[] | select((.tag_name | test("-test")?|not) and (.tag_name | test("-pre")? | not) and .draft != "true" and .prerelease != "true") | .tag_name'
