#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace # uncomment for debugging

csv="${1%.xml}_stemmapoint-readings.csv"

echo "" > "${csv}"

grep -o "wit=\"[^\"]*\"" "${1}" | sed -e "s_\([\"#]\|wit=\|ceteri\)__g" -e "s_ _\n_g" | sed "/^ *$/d" | sort | uniq | \
    while read w;
    do
	echo "Extracting relevant readings from witness ${w}"
	xsltproc --stringparam wit_id "${w}" x-wit-readings.xsl "${1}" >> "${csv}"
    done

sed -i -e  's_, *$__' -e 's_ \+,_,_g' -e 's_, \+_,_g' -e '/^ *$/d' "${csv}"
echo "Cleaned database."
