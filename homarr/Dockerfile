# Homarr, packaged as a Home Assistant app.
#
# The upstream image is pinned to an exact release. Bump this tag and the
# `version` in config.yaml together (see .docs/releasing.md).

FROM ghcr.io/homarr-labs/homarr:v2.12.0

# Brings the Debian packages up to their latest security fixes. jq reads the
# app options; tzdata lets the TZ that the Supervisor passes in apply to the
# server's own clock, not only to Node.
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends jq tzdata \
  && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY homarr-cli /usr/local/bin/homarr-cli
RUN chmod 0755 /run.sh /usr/local/bin/homarr-cli

# The Supervisor shows the app as starting until this check passes, and its
# watchdog restarts the app when the check fails. The live endpoint answers
# through the bundled nginx and checks both the database and Redis, so it only
# passes once the migrations ran and Homarr is ready. It replaces upstream's own
# check for the longer start period, and uses Node because the image has no wget
# or curl.
HEALTHCHECK --start-period=5m --interval=30s --timeout=10s --retries=3 \
  CMD [ "node", "-e", "fetch( 'http://127.0.0.1:7575/api/health/live', { signal: AbortSignal.timeout( 9000 ) } ).then( ( response ) => { process.exitCode = Number( !response.ok ); } ).catch( ( error ) => { console.error( error ); process.exitCode = 1; } )" ]

# run.sh hands over to the upstream entrypoint and run.sh in /app, which start
# nginx, Redis and Next.js and stop them again on SIGTERM. Setting ENTRYPOINT
# also clears the upstream CMD.
ENTRYPOINT [ "/run.sh" ]
