#!/usr/bin/env bash
# Starts the Homarr app: reads the app options, prepares the encryption key and
# environment, then replaces itself with the upstream entrypoint. Upstream's
# /app/run.sh runs the database migrations, starts nginx, Redis and Next.js,
# and stops them again on SIGTERM or SIGINT.

set -euo pipefail

# The Supervisor mounts the app's data folder at /appdata (see config.yaml),
# the folder where Homarr keeps its database, Redis dump and certificates.
readonly DATA_DIR=/appdata
readonly OPTIONS_FILE="$DATA_DIR/options.json"
readonly SECRET_KEY_FILE="$DATA_DIR/secret_encryption_key"
readonly CONSOLE_ENV_FILE=/run/homarr-app/console.env
readonly HOMARR_DIR=/app
readonly BASE_URL_PATTERN='^https?://[^/?#@[:space:]]+$'

# Variables this script exports; written to the console environment as well.
EXPORTED_NAMES=()

log()
{
  echo "[homarr-app] $*"
}

fatal()
{
  log "ERROR: $*" >&2
  exit 1
}

# Prints one option from the app configuration, or nothing when it is unset.
option()
{
  jq -r --arg key "$1" '.[$key] // empty' "$OPTIONS_FILE"
}

# Exports a variable for Homarr and remembers its name for the console.
export_var()
{
  export "$1=$2"
  EXPORTED_NAMES+=( "$1" )
}

read_options()
{
  if [ ! -f "$OPTIONS_FILE" ]
  then
    fatal "$OPTIONS_FILE not found. This image must run as a Home Assistant app that maps its data folder to $DATA_DIR."
  fi

  LOG_LEVEL=$(option log_level)
  NO_EXTERNAL_CONNECTION=$(option no_external_connection)
  BASE_URL=$(option base_url)
  TRUSTED_PROXIES=$(option trusted_proxies)

  # Homarr wants an origin without a path; a trailing slash is a common slip.
  BASE_URL="${BASE_URL%/}"
  if [ -n "$BASE_URL" ] && ! [[ "$BASE_URL" =~ $BASE_URL_PATTERN ]]
  then
    fatal "base_url '$BASE_URL' must be an address such as https://homarr.example.com, without a path."
  fi
}

# Homarr encrypts the integration secrets in its database with this key. It is
# generated once and kept next to the database, so backups always hold both.
prepare_secret_key()
{
  if [ ! -s "$SECRET_KEY_FILE" ]
  then
    log "Generating the encryption key for Homarr's stored secrets."
    ( umask 077 && openssl rand -hex 32 > "$SECRET_KEY_FILE" )
  fi

  SECRET_ENCRYPTION_KEY=$(tr -d '\n\r' < "$SECRET_KEY_FILE")
}

configure_environment()
{
  export_var SECRET_ENCRYPTION_KEY "$SECRET_ENCRYPTION_KEY"
  export_var LOG_LEVEL "${LOG_LEVEL:-info}"
  export_var NO_EXTERNAL_CONNECTION "${NO_EXTERNAL_CONNECTION:-false}"

  # The app has no access to Docker, so its Docker page could only show errors.
  export_var ENABLE_DOCKER false

  if [ -n "$BASE_URL" ]
  then
    export_var BASE_URL "$BASE_URL"
    log "Base URL: $BASE_URL"
  fi

  if [ -n "$TRUSTED_PROXIES" ]
  then
    export_var HOMARR_TRUSTED_PROXIES "$TRUSTED_PROXIES"
  fi

  apply_env_vars
}

# Exports the variables from the env_vars option. They come last, so they can
# override anything above; the Supervisor has already checked the names.
apply_env_vars()
{
  local count
  local index
  local name

  count=$(jq -r '.env_vars // [] | length' "$OPTIONS_FILE")
  for (( index = 0; index < count; index++ ))
  do
    name=$(jq -r --argjson i "$index" '.env_vars[$i].name' "$OPTIONS_FILE")
    export_var "$name" "$(jq -r --argjson i "$index" '.env_vars[$i].value // ""' "$OPTIONS_FILE")"
    log "Setting $name from env_vars."
  done
}

# Stores the settings for the homarr-cli command. Commands run with
# "docker exec" do not inherit this script's environment, and Homarr's command
# line refuses to start without the encryption key.
write_console_env()
{
  local name

  mkdir -p "$(dirname "$CONSOLE_ENV_FILE")"
  ( umask 077 && : > "$CONSOLE_ENV_FILE" )
  for name in "${EXPORTED_NAMES[@]}"
  do
    printf 'export %s=%q\n' "$name" "${!name}" >> "$CONSOLE_ENV_FILE"
  done
}

main()
{
  read_options
  prepare_secret_key
  configure_environment
  write_console_env

  log "Starting Homarr."
  cd "$HOMARR_DIR"
  exec "$HOMARR_DIR/entrypoint.sh" sh run.sh
}

main "$@"
