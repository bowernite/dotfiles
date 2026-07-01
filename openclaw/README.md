# OpenClaw recurring tasks

Source-controlled definitions of my OpenClaw **cron** jobs (the gateway's
built-in scheduler). `cron-jobs.json` is the source of truth; `sync-cron.sh`
applies it to the running gateway.

## Files

- `cron-jobs.json` — declarative list of jobs (matched/updated by `name`).
- `sync-cron.sh` — pushes the manifest to the gateway. Idempotent: creates
  missing jobs, updates existing ones by name, never auto-deletes.

## Usage

```sh
./sync-cron.sh
```

Inspect what's actually live:

```sh
openclaw cron list --all
openclaw cron show <id>
openclaw cron runs --id <id>
```

## Job fields

Each entry in `cron-jobs.json` supports:

| field         | meaning                                                       |
| ------------- | ------------------------------------------------------------- |
| `name`        | stable identity used for create-vs-update matching (required) |
| `description` | freeform note                                                 |
| `cron`        | 5/6-field cron expression (`0 9 * * *`)                        |
| `every`       | fixed interval (`1h`, `10m`) — alternative to `cron`          |
| `at`          | one-shot ISO timestamp or `+duration`                         |
| `tz`          | IANA timezone for `cron` (defaults to gateway host tz)        |
| `session`     | `main` or `isolated`                                          |
| `systemEvent` | payload for `main`-session jobs (a reminder/event)            |
| `message`     | agent prompt for `isolated` jobs                              |
| `wake`        | `now` or `next-heartbeat`                                     |
| `model`       | model override (isolated jobs)                                |
| `thinking`    | thinking level (isolated jobs)                                |
| `announce`    | `true` to fallback-deliver output to a chat                   |
| `channel`     | delivery channel (`imessage`, `slack`, `last`, …)            |
| `to`          | delivery destination                                          |

## Sleep / catch-up behavior (macOS)

Cron runs inside the always-on gateway (`ai.openclaw.gateway` LaunchAgent), not
per-job launchd. Node timers on macOS use `mach_continuous_time`, which keeps
advancing while the Mac sleeps. So a job scheduled for 2pm while the Mac is
asleep 12–4pm fires **once, shortly after wake (~4pm)** — not skipped, not
replayed for every missed window. The next occurrence is recomputed from the
current time. Full gateway restarts have separate catch-up logic
(`MAX_MISSED_JOBS_PER_RESTART = 5`, staggered).

This only holds if the gateway process survives sleep. This machine is a laptop,
so sleep is intentionally left enabled (no `pmset` changes). The
`sudo pmset -a sleep 0 …` guidance in OpenClaw's docs is for always-on
desktop/Mac-mini server hosts and is a battery/heat tradeoff not worth it here.

## Auth note (why sync-cron.sh looks the way it does)

Cron mutation requires `operator.admin`. The default local CLI device identity
is only paired for `operator.read`/`operator.write`, and it can't self-approve
an admin upgrade over loopback (the pending request rotates on every connect —
a deadlock). Workaround: `sync-cron.sh` authenticates as pure **shared-secret**
(the gateway token from `~/.openclaw/openclaw.json`), which the gateway treats
as full operator access. To avoid presenting the limited device identity it runs
each CLI call with a throwaway empty `OPENCLAW_STATE_DIR`, so the connection is
shared-secret only. Real `~/.openclaw` identity files are never touched.
