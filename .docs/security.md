# Security

How the app keeps Homarr's image patched, and what a scan of the image still reports.

## Patching policy

The app runs the official Homarr image unchanged wherever it can. It only patches what can
be replaced safely from outside Homarr's own build:

- **Debian packages.** The Dockerfile runs `apt-get upgrade`, so every build picks up the
  security fixes Debian has published for the image's Debian release.
- **Node.js.** When the upstream image lags behind a Node.js security release, the
  Dockerfile can copy a patched `node` binary, as described below. It does not need to now.

Homarr's npm packages, including Next.js, are compiled into its build. Replacing one inside
the image could break Homarr in ways a quick test does not show, so those wait for an
upstream release, which Dependabot picks up within a day.

## Patched Node.js

Homarr 2.7.0 shipped a Node.js that missed security releases, so the Dockerfile had a
`patched-node` stage that copied a newer binary over it. Homarr 2.11.0 ships Node.js 24.22.2,
the same version that stage last provided, so the stage is gone.

If upstream lags behind again, bring it back with these limits:

- Copy from a Debian image such as `node:<version>-trixie-slim`. The image uses glibc, so a
  binary from an `-alpine` image does not start.
- Keep upstream's major version, so native modules such as `better-sqlite3` and `sharp` keep
  working. Add a Dependabot `ignore` rule for `node` major updates to hold it there.

## Known findings

A [Trivy](https://trivy.dev/) scan of the 2.11.1 image on 2026-11-06 reports nothing in
Homarr's npm packages: every finding listed here for 2.7.0 was fixed upstream.

It does report 56 CVEs in Debian packages (13 High, 43 Medium), none of them with a Debian
fix yet, so `apt-get upgrade` cannot remove them. The same scan of the Alpine-based 2.10.1
image reports none. Part of that gap is a difference in the data, because Alpine's security
database only lists issues with a published fix while Debian's also lists open ones, so the
numbers do not compare directly. These findings have not been assessed one by one. Two groups
were checked:

- **`libsqlite3-0`.** Only `liblastlog2-2` depends on it. Homarr's `better-sqlite3` and
  Node.js bundle their own SQLite, so the database does not use this library.
- **`zlib1g`.** nginx links against it, so CVE-2026-85091 and CVE-2026-27171 are worth
  watching. Node.js has its own bundled copy.

Homarr's own [security advisories](https://github.com/homarr-labs/homarr/security/advisories)
were all fixed before 2.7.0.

To repeat the scan:

```bash
docker build -t local/homarr-app homarr
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest \
  image --scanners vuln --severity MEDIUM,HIGH,CRITICAL local/homarr-app
```

Repeat this at every Homarr update, and update the findings above.
