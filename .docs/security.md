# Security

How the app keeps Homarr's image patched, and the known findings it leaves alone, with the
reason for each.

## Patching policy

The app runs the official Homarr image unchanged wherever it can. It only patches what can
be replaced safely from outside Homarr's own build:

- **Alpine packages.** The Dockerfile runs `apk upgrade`, so every build picks up the
  security fixes Alpine has published for the image's Alpine release.
- **Node.js.** When the upstream image lags behind a Node.js security release, the
  Dockerfile copies the patched `node` binary from the official `node:<version>-alpine`
  image, as described below.

Homarr's npm packages, including Next.js, are compiled into its build. Replacing one inside
the image could break Homarr in ways a quick test does not show, so those wait for an
upstream release, which Dependabot picks up within a day.

## Patched Node.js

Homarr 2.7.0 ships Node.js 24.18.0, which misses the 24.18.1 and 24.22.1 security releases
(among them CVE-2026-56846, CVE-2026-56848 and CVE-2026-58043, rated High). Upstream has
already moved to 24.22.1 for its next release
([homarr-labs/homarr#7267](https://github.com/homarr-labs/homarr/pull/7267)).

The Dockerfile's `patched-node` stage provides that binary, and a build step only swaps it in
when it is a newer release of the same major version, so native modules such as
`better-sqlite3` and `sharp` keep working. The build log shows the decision:
`Node.js 24.18.0 in the image, 24.22.1 patched: replacing`.

Once a Homarr release ships the same or a newer Node.js, the log says `keeping` and the
stage has no effect. Remove the `patched-node` stage and the step that uses it at the next
update after that. Dependabot keeps the stage's tag up to date within the same major
version; it ignores major updates, which the build step would refuse anyway.

## Known findings that do not apply

A [Trivy](https://trivy.dev/) scan of the 2.7.0 image, after the patches above, reports
these findings in Homarr's npm packages. None of them can be reached in Homarr:

| Package | Finding | Why Homarr is not affected |
| --- | --- | --- |
| `next` 16.3.6 | CVE-2026-94483, SSRF in image optimisation | Only applies with `images.remotePatterns`; Homarr allows local images only. |
| `next` 16.3.6 | CVE-2026-94484, cache poisoning | Needs a root-level catch-all page; Homarr has none. |
| `next` 16.3.6 | CVE-2026-94485, metadata image routes | Needs `opengraph-image` or `twitter-image` routes; Homarr has none. |
| `next` 16.3.6 | CVE-2026-94543, cache poisoning | Pages Router only; Homarr uses the App Router. |
| `next` 16.3.6 | CVE-2026-94544, Draft Mode leak | Needs Draft Mode; Homarr does not use it. |
| `sharp` 0.35.4 | GHSA-wq5f-xc86-pv6w, librsvg | Needs sharp to decode SVG. Next.js does not pass SVG to sharp without `dangerouslyAllowSVG`, which Homarr does not set, and the advisory concerns glibc systems, while the image uses musl. |
| `source-map-js` 1.2.1 | CVE-2026-93749, denial of service | Needs an attacker-supplied source map; Homarr only reads its own. |
| `dompurify` 3.4.11 | GHSA-55q2-fjhq-7xh7, XSS | Needs `IN_PLACE` sanitising with hooks; Homarr does not use `IN_PLACE`. |

Homarr's own [security advisories](https://github.com/homarr-labs/homarr/security/advisories)
were all fixed before 2.7.0.

To repeat the scan:

```bash
docker build -t local/homarr-app homarr
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest \
  image --scanners vuln --severity MEDIUM,HIGH,CRITICAL local/homarr-app
```

Review this list at every Homarr update, and remove the rows that the new release fixes.
