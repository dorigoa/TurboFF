#!/bin/bash
# Starts TurboFieldfareServer in the background with one of the .gturbo models and
# returns once its API answers (/v1/models), or as soon as the server exits.
# The server keeps running after this script (and the ssh session) ends; its log
# is ./turboff-<timestamp>.log next to this script. Stop it with ./stop.sh.
#
# Used by llm-console (Mac tab), e.g.:
#   ~/TurboFF/run-turboff.sh -model gemma4-8bit -ctx 262144 -host 192.168.1.101 -port 8080

set -uo pipefail

usage() {
    echo "Usage: $0 [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  -model <name>    Model in $models_dir: gemma4-8bit (default), gemma4, qwen36" >&2
    echo "  -ctx <tokens>    Context size: 262144 (default), 131072, 65536, ..." >&2
    echo "  -host <address>  Address to listen on (default: 127.0.0.1)" >&2
    echo "  -port <number>   Port (default: 8080)" >&2
    echo "  -wait <seconds>  How long to wait for the API (default: 300)" >&2
    exit 2
}

models_dir=/Volumes/Home/TurboFieldFareModel
server="$HOME/.local/bin/TurboFieldfareServer"
model=gemma4-8bit
context=262144
host=127.0.0.1
port=8080
wait_s=300

while [[ $# -gt 0 ]]; do
    case "$1" in
        -model) model="${2:-}"; shift 2 ;;
        -ctx)   context="${2:-}"; shift 2 ;;
        -host)  host="${2:-}"; shift 2 ;;
        -port)  port="${2:-}"; shift 2 ;;
        -wait)  wait_s="${2:-}"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

dir="$models_dir/$model.gturbo"
[[ -f "$dir/manifest.json" ]] || { echo "No model $model: $dir/manifest.json not found" >&2; exit 2; }
[[ -x "$server" ]] || { echo "$server not found" >&2; exit 2; }

# Another server on the port would answer /v1/models in our place.
busy=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null)
if [[ -n "$busy" ]]; then
    echo "Port $port is already in use:" >&2
    echo "$busy" >&2
    exit 1
fi

cd "$(dirname "$0")" || exit 2
log="$PWD/turboff-$(date +%Y%m%d-%H%M%S).log"
echo "Starting TurboFieldfareServer: $model.gturbo, context $context, $host:$port"
nohup "$server" --model "$dir" --host "$host" --port "$port" --max-context "$context" \
    --accept-any-model </dev/null >"$log" 2>&1 &
pid=$!
echo "pid $pid, log $log"

url="http://$host:$port/v1/models"
for (( waited = 0; waited < wait_s; waited += 2 )); do
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "TurboFieldfareServer exited. Last lines of $log:" >&2
        tail -n 20 "$log" >&2
        exit 1
    fi
    if curl -fs -o /dev/null --max-time 5 "$url"; then
        echo "Ready: $url"
        exit 0
    fi
    sleep 2
done
echo "No answer from $url after $wait_s s; the server is still running (pid $pid), see $log" >&2
exit 1
