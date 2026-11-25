# Plan: a custom AppArmor profile

Started 2026-11-25. Status: not started.

## Goal

Give the app its own AppArmor profile (`homarr/apparmor.txt`), so Home Assistant raises its
security rating from 5 to 6. Beyond the score, the profile should take away what Homarr never
needs, such as most root capabilities, raw sockets and kernel interfaces, without breaking
anything users rely on.

## Why 6 is the ceiling

Home Assistant starts every app at 5, on a scale of 1 to 8
([security rating reference](https://contributors.home-assistant.io/apps/reference/security-rating/)).
The app loses no points today: it uses no host network, no extra privileges, no Supervisor
role and no Docker access. Of the bonuses, only the AppArmor one is within reach:

| Bonus | Points | Possible here |
|---|---|---|
| `ingress: true` | +2 | No. Homarr breaks under the ingress sub-path ([Development](../development.md), "No ingress") |
| No ingress and no port mapped to the host | +2 | No. Port 7575 is the only way in |
| `auth_api: true` | +1 | No. Homarr has its own accounts and never checks Home Assistant credentials |
| Custom AppArmor profile | +1 | Yes |

Only one of the first three bonuses ever counts, so ingress later would still give 8 at most.

## What the profile has to allow

Unlike the example in Home Assistant's
[Secure your app](https://contributors.home-assistant.io/apps/guides/security/) guide, this
app does not use S6 overlay or Bashio. Docker's own init (`init: true`) starts `/run.sh`, which
hands over to the upstream entrypoint. Everything below runs under the profile, including
processes started with `docker exec`: the health check and `homarr-cli`.

| Area | What runs or is touched |
|---|---|
| Init and scripts | `/sbin/docker-init`, `/run.sh` (bash), `/app/entrypoint.sh` and `sh /app/run.sh`, `/usr/local/bin/homarr-cli`, `/usr/bin/homarr` |
| Tools used by the scripts | `jq`, `openssl`, `envsubst`, `grep`, `id`, `mkdir`, `tr`, `cat`, `dirname`, `sleep`, `setpriv` (only when `PUID`/`PGID` are set) |
| Services | `/usr/sbin/nginx` (master as root, workers as `www-data`), `/usr/local/bin/redis-server`, `/usr/local/bin/node` for migrations, Next.js, the WebSocket server, `trusted-proxies.mjs`, the CLI and the health check |
| Homarr code | `/app/**` read; native modules (`better-sqlite3`) need `m`; `/app/apps/nextjs/.next/cache/**` read and write |
| Data | `/appdata/**` read, write and lock: SQLite database, Redis dump, certificates, the encryption key, `options.json` |
| Runtime files | `/run/**` (`/run/nginx`, `/run/homarr-app/console.env`), `/tmp/**`, `/var/cache/nginx`, `/var/lib/nginx`, `/var/log/nginx`, `/etc/nginx/nginx.conf` (written by `envsubst` on every start) |
| Kernel interfaces | `/proc/net/if_inet6` (IPv6 check in upstream `run.sh`), `/proc/**` and `/sys/fs/cgroup/**` reads by Node, `/dev/tty` for `docker exec -it` |
| Network | TCP and UDP over IPv4 and IPv6 (port 7575, loopback to 3000, 3001 and Redis, outgoing calls to integrations, DNS), Unix sockets |
| Capabilities | Probably `chown`, `dac_override`, `fowner`, `setuid` and `setgid` (nginx dropping to `www-data`, `setpriv`), `kill`; the audit log decides |
| Signals | Sending and receiving `term`, `int`, `kill`, `hup` and `cont` between processes inside the app, for shutdown and the Next.js restart loop |

## Steps

1. **Draft the profile.** Write `homarr/apparmor.txt` with one top-level profile named
   `homarr` (the Supervisor renames it to the app ID on load), with
   `flags=(attach_disconnected,mediate_deleted,complain)`. Base it on the guide's example
   without the S6 and Bashio parts, plus the table above. Start with explicit path rules
   rather than the example's blanket `file,` rule: a profile that allows every file adds
   the rating point but little protection.
2. **Install a local copy in complain mode.** AppArmor is only enforced on a real Home
   Assistant OS or Supervised host; Docker Desktop and the development container do not
   load the profile. Install the `homarr/` folder as a local app
   ([Development](../development.md), step 4) on a second port, with a copy of real data.
3. **Exercise everything.** Fresh install and onboarding, an upgrade on existing data,
   boards with integrations (including ones over HTTPS with a trusted certificate), the
   WebSocket-driven widgets, `homarr-cli users list`, `env_vars` with `PUID`/`PGID`, a
   restart, a stop (Redis must still save its dump), the watchdog after killing Next.js,
   and a backup and restore.
4. **Read what was allowed.** Collect the `apparmor="ALLOWED"` lines from the host's audit
   log. On Home Assistant OS, find out where they can be read (host journal through SSH on
   port 22222, or `dmesg` from the Advanced SSH & Web Terminal app with protection mode off)
   and note it in [Development](../development.md). Add each missing rule to the profile and
   repeat steps 3 and 4 until the log stays empty.
5. **Enforce.** Remove `complain`, rebuild, and repeat step 3 once more. Check that the app
   page shows a rating of 6, and that nothing new appears as `apparmor="DENIED"`.
6. **Document.**
   - [Development](../development.md): add `apparmor.txt` to the repository layout, a design
     decision on what the profile allows and why, and how to debug it.
   - [Releasing](../releasing.md): add "a changed upstream binary or path" to *Changes to
     watch for*, with the advice to test each Homarr update in enforce mode; a new path in
     upstream's image now breaks the app instead of passing silently.
   - [`homarr/DOCS.md`](../../homarr/DOCS.md): a troubleshooting line on recognising an
     AppArmor denial in the log.
7. **Release** as app-only version `2.14.0.1` (or the next Homarr version if it comes
   first), with a changelog entry. The profile is loaded when the app is installed or
   updated, so existing users get the new rating with this update.

## Risks

- **Upstream changes break the app.** Homarr 2.14.0 alone moved nginx to the nginx.org
  package. Every Dependabot update then needs a run in enforce mode before merging, which
  makes releases slower. The Complete Homarr update workflow does not catch this: it only
  builds the image and never runs it under the profile (see the open questions).
- **Rarely used paths.** Features nobody tested in step 3 (for example a particular
  integration or the Certificates page) may only fail for some users. Keep the rules for
  `/appdata`, `/app` and the network broad enough that a new feature does not need a new
  rule.
- **Debugging on Home Assistant OS.** Reading the host's audit log needs host access. If
  that turns out to be impractical, fall back to the guide's broad `file,` rule with
  limited capabilities and network: still the rating point, less protection.

## Open questions

- Is the rating point worth slower releases? If not, stop after step 1 with a broad
  profile, or drop the plan.
- Can the profile be tested in CI or the development container at all, for example on a
  Linux runner with AppArmor enabled? GitHub's Ubuntu runners have AppArmor; worth a check
  before step 2.
