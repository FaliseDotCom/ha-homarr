# Homarr, packaged as a Home Assistant app.
#
# The upstream image is pinned to an exact release. Bump this tag and the
# `version` in config.yaml together (see .docs/releasing.md).
FROM ghcr.io/homarr-labs/homarr:v2.7.0

# jq reads the app options; tzdata lets the TZ that the Supervisor passes in
# apply to the server's own clock, not only to Node.
RUN apk add --no-cache jq tzdata

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
