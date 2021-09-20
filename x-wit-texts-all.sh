#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace # uncomment for debugging

date="$(date +%Y-%m-%d)"

grep -o "wit=\"[^\"]*\"" "${1}" | sed -e "s_\([\"#]\|wit=\|ceteri\)__g" -e "s_ _\n_g" | sed "/^ *$/d" | sort | uniq | \
    while read w;
    do
	echo "Extracting witness ${w}"
	xsltproc --output wit_texts/"${1%.xml}_${w}".xml --stringparam wit_id "${w}" --stringparam date "${date}" x-wit-text.xsl "${1}"
    done
