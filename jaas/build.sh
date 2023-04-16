#!/bin/sh
### This script is used to build the sasl_jaas.conf file.
### It is used to inject a random password into the file.

pwd=$(dirname "$0")
echo "----- pwd: $pwd"

mkdir -p "$pwd/build"

src="$pwd/src/sasl_jaas.conf"
dst="$pwd/build/sasl_jaas.conf"

echo "----- src: $src"
echo "----- dst: $dst"

search_string="{{random_password}}"

# Random password generator, literal.
# shellcheck disable=SC2016
random_generator='$(openssl rand -base64 15 | tr -dc "a-zA-Z0-9" | cut -c1-16)'

# Inject random password generator into destination content.
# PS: Regex s/\\\"/\\\\\"/g used to prevent double quotes from being escaped.
dst_raw=$(sed "s/$search_string/$random_generator/g;s/\\\"/\\\\\"/g" "$src")
dst_cmd="echo \"$dst_raw\""
echo "----- dst_cmd: $dst_cmd"

# Evaluate destination content and write to destination file.
eval "$dst_cmd" > "$dst"
