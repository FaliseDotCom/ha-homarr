# Releasing

The app version always equals the Homarr version it contains, so users see the Homarr
version in Home Assistant.

## Updating to a new Homarr release

This repository does not contain Homarr's source code. The app is built from the official
Homarr image, so updating Homarr means pointing the app at a newer image tag.

### With the update script

From the repository root, in Git Bash or any other Bash shell, with Docker running:

```bash
scripts/update-homarr.sh          # latest Homarr release
scripts/update-homarr.sh 2.8.0    # a specific release
```

The script checks that the image exists for both architectures, refuses downgrades,
updates the version in all files, adds a changelog entry and builds the image. It does not
commit anything. Then do steps 2, 5 and 6 below: read the release notes, test the upgrade,
and commit, tag and push.

### By hand

1. Check the new release on the
   [GitHub releases page](https://github.com/homarr-labs/homarr/releases), for example
   `v2.8.0`, and confirm its image lists both `linux/amd64` and `linux/arm64`:

   ```bash
   docker buildx imagetools inspect ghcr.io/homarr-labs/homarr:v2.8.0
   ```

2. Read the [Homarr release notes](https://github.com/homarr-labs/homarr/releases) for
   changes to the Docker image, especially its `Dockerfile`, `scripts/entrypoint.sh`,
   `scripts/run.sh` and environment variables.
3. Update the version in three places:
   - the `FROM` line in `homarr/Dockerfile` (with the leading `v`)
   - `version` in `homarr/config.yaml` (without it)
   - the Homarr badge in `README.md`
4. Add an entry at the top of `homarr/CHANGELOG.md` that links to the Homarr release notes.
5. Test as described in [Development](development.md). Always test an upgrade from the
   previous release, not only a fresh install: start the old version with data, then the new
   version on the same `test/data` folder.
6. Commit, tag the commit with the version (`git tag 2.8.0`), and push both. Home Assistant
   offers the update to users the next time it checks the repository.

## App-only changes

For a change to the app itself without a new Homarr release, add a fourth version segment:
`2.7.0` becomes `2.7.0.1`, then `2.7.0.2`. The next Homarr release resets it.

## Changes to watch for

- **A changed entrypoint or `run.sh`.** The app relies on `/app/entrypoint.sh` taking the
  command to run as its arguments, on `/app/run.sh` being started as `sh run.sh` from `/app`,
  and on the upstream `run.sh` stopping its processes on `SIGTERM`.
- **Paths under `/appdata`.** The app maps its data folder there; a new upstream data
  location must stay inside `/appdata` or it is lost on every restart.
- **The health endpoint.** The health check uses `/api/health/live` and BusyBox `wget`.
  Check that both still exist, and that Homarr's request proxy still skips `/api`.
- **New required environment variables.** `run.sh` provides `SECRET_ENCRYPTION_KEY`; a new
  required secret needs the same treatment.
- **A move away from SQLite.** Homarr v2 dropped MySQL. A change to the default database
  would need a migration path for existing installations.
- **Supervisor changes.** Check the
  [app configuration reference](https://developers.home-assistant.io/docs/apps/configuration)
  for deprecations, and watch the Supervisor log for warnings about this app.
