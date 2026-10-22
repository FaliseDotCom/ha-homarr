#!/usr/bin/env bash
# Updates the app to a new Homarr release: checks the upstream image, bumps the
# version everywhere it appears, adds a changelog entry and builds the image.
# It never commits or pushes; it prints the git commands to run afterwards.
#
# Usage: scripts/update-homarr.sh [version]
#   version  Homarr version such as 2.8.0. Defaults to the latest GitHub release.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly REPO_ROOT
readonly DOCKERFILE="$REPO_ROOT/homarr/Dockerfile"
readonly CONFIG="$REPO_ROOT/homarr/config.yaml"
readonly CHANGELOG="$REPO_ROOT/homarr/CHANGELOG.md"
readonly README="$REPO_ROOT/README.md"
readonly IMAGE=ghcr.io/homarr-labs/homarr
readonly RELEASES_API=https://api.github.com/repos/homarr-labs/homarr/releases/latest
readonly RELEASES_URL=https://github.com/homarr-labs/homarr/releases/tag
readonly VERSION_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+$'

fatal()
{
  echo "ERROR: $*" >&2
  exit 1
}

# Homarr tags its releases and images with a leading "v"; the app version has none.
latest_release()
{
  curl -fsSL "$RELEASES_API" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1
}

current_version()
{
  sed -n "s|^FROM $IMAGE:v\(.*\)$|\1|p" "$DOCKERFILE"
}

# The Supervisor architectures amd64 and aarch64 need linux/amd64 and linux/arm64.
check_image()
{
  local manifest
  manifest=$(docker buildx imagetools inspect "$IMAGE:v$1") || fatal "Image $IMAGE:v$1 not found."

  local platform
  for platform in linux/amd64 linux/arm64
  do
    if ! grep -q "Platform: *$platform\$" <<< "$manifest"
    then
      fatal "Image $IMAGE:v$1 has no $platform build."
    fi
  done
}

update_files()
{
  local old="$1"
  local new="$2"

  sed -i "s|^FROM $IMAGE:v$old\$|FROM $IMAGE:v$new|" "$DOCKERFILE"
  sed -i "s|^version: \".*\"\$|version: \"$new\"|" "$CONFIG"
  sed -i "s|Homarr $old|Homarr $new|; s|Homarr-$old-|Homarr-$new-|" "$README"
}

# Inserts the new entry above the first existing release heading.
add_changelog_entry()
{
  local new="$1"
  local entry="## $new\n\n- Homarr $new. See the [Homarr $new release notes]($RELEASES_URL/v$new).\n"

  awk -v entry="$entry" '!done && /^## / { printf "%s\n", entry; done = 1 } { print }' "$CHANGELOG" > "$CHANGELOG.tmp"
  mv "$CHANGELOG.tmp" "$CHANGELOG"
}

main()
{
  local new="${1:-}"

  if [ -z "$new" ]
  then
    new=$(latest_release)
  fi

  new="${new#v}"
  if ! [[ "$new" =~ $VERSION_PATTERN ]]
  then
    fatal "'$new' is not a Homarr version such as 2.8.0."
  fi

  local old
  old=$(current_version)

  if [ "$old" = "$new" ]
  then
    echo "Already on Homarr $new."
    exit 0
  fi

  # Homarr migrates the database on start, so an older image cannot run on it.
  if [ "$(printf '%s\n' "$old" "$new" | sort -V | tail -n 1)" = "$old" ]
  then
    fatal "Homarr $new is older than the current $old; downgrades are not supported."
  fi

  echo "Updating Homarr $old -> $new"
  check_image "$new"
  update_files "$old" "$new"
  add_changelog_entry "$new"

  echo "Building the image to check it still builds..."
  docker build -t local/homarr-app "$REPO_ROOT/homarr"

  cat <<EOF

Homarr $old -> $new prepared. Next:

  1. Read the release notes: $RELEASES_URL/v$new
  2. Test an upgrade on existing data (see .docs/development.md).
  3. Review the diff and release:

       git diff
       git commit -am "Update Homarr to $new"
       git tag $new
       git push && git push --tags
EOF
}

main "$@"
