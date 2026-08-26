#!/bin/bash
#
# nginx-log-analyser.sh
# Usage: ./nginx-log-analyser.sh /path/to/nginx-access.log
#
# Note: deliberately NOT using "pipefail". With pipefail, `head` closing
# the pipe early (after reading 5 lines) sends SIGPIPE upstream to `sort`,
# and bash treats that as a script-ending error. set -u alone is enough here.
set -u

LOG_FILE="${1:-nginx-access.log}"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: log file '$LOG_FILE' not found." >&2
    exit 1
fi

# Reformats "  count  value..." (from `uniq -c`) into "value... - count requests".
# Using awk here (not the naive "print $2, $1" trick) matters because values
# like paths or user agents can contain spaces -- $2 alone would truncate them.
format_report() {
    awk '{count=$1; $1=""; sub(/^ /,""); print $0 " - " count " requests"}'
}

echo "Top 5 IP addresses with the most requests:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 5 | format_report

echo
echo "Top 5 most requested paths:"
awk -F'"' '{print $2}' "$LOG_FILE" | awk '{print $2}' | sort | uniq -c | sort -rn | head -n 5 | format_report

echo
echo "Top 5 response status codes:"
awk -F'"' '{print $3}' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 5 | format_report

echo
echo "Top 5 user agents:"
awk -F'"' '{print $6}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 5 | format_report
