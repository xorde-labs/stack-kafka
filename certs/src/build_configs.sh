#!/bin/sh
### This scripts is fully POSIX compliant.

#set -x
dir_out="${2:-../build/config}"
dir_in=$(dirname "$0")

#Define the variable string containing the words
token="[ alt_names ]"
hosts="${1:-localhost kafka0 kafka1}"
file_in="$dir_in/cert.cnf"
file_out="$dir_out/cert.cnf"

mkdir -p "$dir_out" # Create the directory if it does not exist

array=$(echo "$hosts" | tr ' ' '\n') # Convert the string to a newline separated strings
block="${token}\n" # Initialize the block variable
while read -r host; do
  counter=$((${counter:-0}+1)) # Increment counter with 0 as default value
  line="DNS.$counter=$host" # Form the line
  block="${block}${line}\\n" # Append the line to the block variable
done <<array_input # Please see https://github.com/koalaman/shellcheck/wiki/SC2031#correct-code for more information.
$array
array_input

line_num=$(grep -Fn "$token" "$file_in"); line_num=${line_num%%:*} # Get the line number of the token in file_in
sed "${line_num}s/.*/$block/g" "$file_in" > "$file_out" # Replace the line with the block

# Copy the ca.cnf file to the certs directory
file_in="$dir_in/ca.cnf"
file_out="$dir_out/ca.cnf"
cp "$file_in" "$file_out"
