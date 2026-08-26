# Nginx Log Analyser

A Bash script that parses an Nginx access log (Combined Log Format) and reports the top 5 IP addresses, requested paths, response status codes, and user agents.

Built as a solution to the [Nginx Log Analyser](https://roadmap.sh/projects/nginx-log-analyser) project from [roadmap.sh](https://roadmap.sh/).

## Features

- Top 5 IP addresses by request count
- Top 5 most requested paths
- Top 5 response status codes
- Top 5 user agents
- Accepts any log file path as an argument, with a sane default
- Handles multi-word fields (paths, user agents) correctly instead of truncating on the first space

## Requirements

- Bash
- Standard Unix tools: `awk`, `sort`, `uniq`, `head` (available by default on Linux and macOS)

## Usage

```bash
chmod +x nginx-log-analyser.sh
./nginx-log-analyser.sh /path/to/nginx-access.log
```

If no path is given, the script looks for `nginx-access.log` in the current directory:

```bash
./nginx-log-analyser.sh
```

## Sample Output

```
Top 5 IP addresses with the most requests:
178.128.94.113 - 1087 requests
142.93.136.176 - 1087 requests
138.68.248.85 - 1087 requests
159.89.185.30 - 1086 requests
86.134.118.70 - 277 requests

Top 5 most requested paths:
/v1-health - 4560 requests
/ - 270 requests
/v1-me - 232 requests
/v1-list-workspaces - 127 requests
/v1-list-timezone-teams - 75 requests

Top 5 response status codes:
200 - 5740 requests
404 - 937 requests
304 - 621 requests
400 - 260 requests
403 - 23 requests

Top 5 user agents:
DigitalOcean Uptime Probe 0.22.0 (https://digitalocean.com) - 4347 requests
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 - 513 requests
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 - 332 requests
Custom-AsyncHttpClient - 294 requests
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 - 282 requests
```

## How It Works

Each report follows the same pipeline pattern:

```
extract field -> sort -> uniq -c -> sort -rn -> head -n 5 -> format
```

- **Extract**: `awk` pulls out the relevant field. IP addresses are the first whitespace-separated field; paths, status codes, and user agents are extracted by splitting on `"` since they sit inside the quoted request/user-agent sections of the log line.
- **Sort + uniq -c**: groups identical values and counts occurrences (`uniq -c` requires sorted input to count correctly).
- **Sort -rn**: orders counts numerically, highest first.
- **Head -n 5**: keeps only the top 5.
- **Format**: a small `format_report` function reassembles `uniq -c`'s `"  count  value"` output into `"value - count requests"`. This is done with `awk` rather than a simple `print $2, $1` because values like paths and user agents can contain spaces, which would otherwise get truncated to their first word.

The script intentionally does not use `set -o pipefail`, since `head` closing the pipe early (after reading 5 lines) sends `SIGPIPE` upstream and `pipefail` would treat that as a script-ending error. `set -u` alone is sufficient here.

## Project Structure

```
.
├── nginx-log-analyser.sh   # main script
├── nginx-access.log        # sample log file (Combined Log Format)
└── README.md
```

## Log Format

The script expects the Nginx Combined Log Format:

```
<ip> - - [<date>] "<method> <path> <protocol>" <status> <size> "<referrer>" "<user agent>"
```

Example:

```
178.128.94.113 - - [04/Oct/2024:00:00:18 +0000] "GET /v1-health HTTP/1.1" 200 51 "-" "DigitalOcean Uptime Probe 0.22.0 (https://digitalocean.com)"
```

## Author

Built by [madousang](https://github.com/madousang/) as part of practicing shell scripting and log analysis for the [roadmap.sh](https://roadmap.sh/) DevOps track.


