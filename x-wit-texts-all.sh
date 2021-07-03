#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace # uncomment for debugging

grep -o "wit=\"[^\"]*\"" hp_1.1-20.xml | sed -e "s_\([\"#]\|wit=\|ceteri\)__g" -e "s_ _\n_g" | sed "/^ *$/d" | sort | uniq | \
    while read w;
    do
	echo "Extracting witness ${w}"
	xsltproc --output wit_texts/hp_1.1-20_"${w}".xml --stringparam wit_id "${w}" x-wit-text.xsl hp_1.1-20.xml
    done
