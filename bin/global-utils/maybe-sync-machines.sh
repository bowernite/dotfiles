# Fires off a machine sync at most once per 10min (non-blocking — errors already
# surface via an OS notification).
maybe_sync_machines() {
  local marker="${HOME}/.cache/cc-last-sync"
  if [[ -z $(find "$marker" -mmin -10 2>/dev/null) ]]; then
    # Mark up-front so a slow/failed sync doesn't re-run every launch.
    mkdir -p "${marker:h}" && touch "$marker"
    (~/src/personal/AGENTS/sync-machines.sh &>/dev/null &)
  fi
}
