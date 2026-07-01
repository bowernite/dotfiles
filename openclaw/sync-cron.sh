#!/usr/bin/env bash
# Applies openclaw/cron-jobs.json to the running OpenClaw gateway.
# Source of truth is the JSON file; this script makes the gateway match it.
# Jobs are matched/updated by "name". Jobs that exist in the gateway but not
# in the manifest are reported, never auto-deleted.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DIR/cron-jobs.json"

if ! command -v openclaw >/dev/null 2>&1; then
  # fnm-managed installs often aren't on a login-less PATH
  for candidate in "$HOME"/.local/share/fnm/node-versions/*/installation/bin/openclaw; do
    if [ -x "$candidate" ]; then
      export PATH="$(dirname "$candidate"):$PATH"
      break
    fi
  done
fi
command -v openclaw >/dev/null 2>&1 || { echo "openclaw CLI not found on PATH" >&2; exit 1; }

# Authenticate with the shared gateway token, which is treated as full operator
# access. This avoids the device-scope pairing deadlock a fresh CLI identity
# hits when it only holds operator.write and tries to self-approve an upgrade.
CONFIG="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
GW_URL="$(node -e "const c=require('$CONFIG');console.log(c.gateway?.remote?.url||'ws://127.0.0.1:'+(c.gateway?.port||18789))")"
GW_TOKEN="$(node -e "const c=require('$CONFIG');console.log(c.gateway?.auth?.token||'')")"
AUTH=(--url "$GW_URL")
[ -n "$GW_TOKEN" ] && AUTH+=(--token "$GW_TOKEN")

oc() { openclaw "$@" "${AUTH[@]}"; }

existing_json="$(oc cron list --all --json)"

job_count="$(jq '.jobs | length' "$MANIFEST")"
manifest_names="$(jq -r '.jobs[].name' "$MANIFEST")"

for i in $(seq 0 $((job_count - 1))); do
  job="$(jq -c ".jobs[$i]" "$MANIFEST")"
  name="$(jq -r '.name' <<<"$job")"

  args=(--name "$name")
  jq -e 'has("description")' <<<"$job" >/dev/null && args+=(--description "$(jq -r '.description' <<<"$job")")
  jq -e 'has("cron")'        <<<"$job" >/dev/null && args+=(--cron "$(jq -r '.cron' <<<"$job")")
  jq -e 'has("every")'       <<<"$job" >/dev/null && args+=(--every "$(jq -r '.every' <<<"$job")")
  jq -e 'has("at")'          <<<"$job" >/dev/null && args+=(--at "$(jq -r '.at' <<<"$job")")
  jq -e 'has("tz")'          <<<"$job" >/dev/null && args+=(--tz "$(jq -r '.tz' <<<"$job")")
  jq -e 'has("session")'     <<<"$job" >/dev/null && args+=(--session "$(jq -r '.session' <<<"$job")")
  jq -e 'has("message")'     <<<"$job" >/dev/null && args+=(--message "$(jq -r '.message' <<<"$job")")
  jq -e 'has("systemEvent")' <<<"$job" >/dev/null && args+=(--system-event "$(jq -r '.systemEvent' <<<"$job")")
  jq -e 'has("wake")'        <<<"$job" >/dev/null && args+=(--wake "$(jq -r '.wake' <<<"$job")")
  jq -e 'has("model")'       <<<"$job" >/dev/null && args+=(--model "$(jq -r '.model' <<<"$job")")
  jq -e 'has("thinking")'    <<<"$job" >/dev/null && args+=(--thinking "$(jq -r '.thinking' <<<"$job")")
  jq -e '.announce == true'  <<<"$job" >/dev/null && args+=(--announce)
  jq -e 'has("channel")'     <<<"$job" >/dev/null && args+=(--channel "$(jq -r '.channel' <<<"$job")")
  jq -e 'has("to")'          <<<"$job" >/dev/null && args+=(--to "$(jq -r '.to' <<<"$job")")

  existing_id="$(jq -r --arg n "$name" '.jobs[] | select(.name == $n) | .id' <<<"$existing_json" | head -1)"

  if [ -n "$existing_id" ]; then
    echo "updating: $name ($existing_id)"
    oc cron edit "$existing_id" "${args[@]}" >/dev/null
  else
    echo "creating: $name"
    oc cron add "${args[@]}" >/dev/null
  fi
done

orphans="$(jq -r --argjson names "$(jq -c '[.jobs[].name]' "$MANIFEST")" \
  '.jobs[] | select(.name as $n | $names | index($n) | not) | .name' <<<"$existing_json")"
if [ -n "$orphans" ]; then
  echo
  echo "Note: gateway has jobs not in $MANIFEST (not touched):"
  echo "$orphans" | sed 's/^/  - /'
fi
