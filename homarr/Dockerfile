# Homarr, packaged as a Home Assistant app.
#
# The upstream image is pinned to an exact release. Bump this tag and the
# `version` in config.yaml together (see .docs/releasing.md).

# A Node.js release with security fixes the upstream image does not have yet.
# Only used when it is newer than upstream's Node with the same major version;
# see the RUN step below.
FROM node:24.22.1-alpine3.24 AS patched-node

FROM ghcr.io/homarr-labs/homarr:v2.7.0

COPY --from=patched-node /usr/local/bin/node /tmp/node-patched

# Brings the Alpine packages up to their latest security fixes. jq reads the
# app options; tzdata lets the TZ that the Supervisor passes in apply to the
# server's own clock, not only to Node.
RUN apk upgrade --no-cache \
  && apk add --no-cache jq tzdata

# Replaces upstream's Node with the patched one when that is a newer release of
# the same major version, so native modules such as better-sqlite3 keep working.
# Once upstream ships the same or a newer Node, upstream's is kept.
RUN /tmp/node-patched -e ' \
    const current = process.argv[ 1 ].split( "." ).map( Number ); \
    const patched = process.versions.node.split( "." ).map( Number ); \
    const newer = patched[ 0 ] === current[ 0 ] \
      && ( patched[ 1 ] > current[ 1 ] || ( patched[ 1 ] === current[ 1 ] && patched[ 2 ] > current[ 2 ] ) ); \
    console.log( `Node.js ${ process.argv[ 1 ] } in the image, ${ process.versions.node } patched: ${ newer ? "replacing" : "keeping" }` ); \
    process.exit( newer ? 0 : 1 );' "$(node -p process.versions.node)" \
  && mv /tmp/node-patched /usr/local/bin/node \
  || rm -f /tmp/node-patched

COPY run.sh /run.sh
COPY homarr-cli /usr/local/bin/homarr-cli
RUN chmod 0755 /run.sh /usr/local/bin/homarr-cli

# The Supervisor shows the app as starting until this check passes, and its
# watchdog restarts the app when the check fails. The live endpoint answers
# through the bundled nginx and checks both the database and Redis, so it only
# passes once the migrations ran and Homarr is ready.
HEALTHCHECK --start-period=5m --interval=30s --timeout=10s --retries=3 \
  CMD [ "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:7575/api/health/live" ]

# run.sh hands over to the upstream entrypoint and run.sh in /app, which start
# nginx, Redis and Next.js and stop them again on SIGTERM. Setting ENTRYPOINT
# also clears the upstream CMD.
ENTRYPOINT [ "/run.sh" ]
