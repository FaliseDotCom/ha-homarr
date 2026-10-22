# Homarr

[Homarr](https://homarr.dev/) is a free, open-source dashboard for your home lab. It brings
your services together on boards you arrange in the browser: links with status pings, and
widgets for media servers, downloads, DNS blockers, calendars, weather and Home Assistant
entities. This app runs Homarr on your Home Assistant server, with its own database, so there
is nothing else to install.

## Requirements

- Home Assistant OS or a Supervised installation, version 2026.7 or later.
- A 64-bit system: `amd64` (most PCs and NUCs) or `aarch64` (Raspberry Pi 4 or 5, and
  most other ARM boards).
- Around 1 GB of free disk space for the app, plus room for your data.
- Around 400 MB of free memory while Homarr is running.

## Installation

1. Add this repository to Home Assistant. Go to **Settings** > **Apps** > **Install app**,
   open the three-dots menu in the top-right corner, select **Repositories**, then add:

   ```text
   https://github.com/FaliseDotCom/ha-homarr
   ```

2. Find **Homarr** in the app store and select **Install**.
3. On the **Info** tab, turn on **Watchdog**, and select **Start**.
4. Open the **Log** tab. Homarr is ready when the log shows `Ready in`, and the app no longer
   shows as *starting*.
5. Select **Open web UI** and complete the [first start](#first-start) right away.

## First start

Homarr has no account yet when it starts for the first time. Instead, the first visit opens
an onboarding wizard that creates the administrator account and sets a few defaults. Anyone
who can reach Homarr before you start it could create that account, so open it as soon as the
app has started. Once started, the wizard is locked to your browser.

1. Select **Get started**, or **Restore backup** to bring in the data of another Homarr
   installation.
2. Create your administrator account: a user name and a password of at least 8 characters.
3. Pick the default language and theme, and the address your other services run on, such as
   your Home Assistant server's IP address. Homarr uses it to fill in the addresses of the
   services it finds.
4. Follow the remaining steps to connect services and build your first board, or skip them
   and do this later.

Homarr sends anonymous usage statistics, such as the number of widgets and its version, from
the first start. To stop that, turn off **Help us improve Homarr** under **Management** >
**Settings** > **Analytics**.

Homarr's
[getting started guide](https://homarr.dev/docs/getting-started/after-the-installation) walks
you through apps, integrations and widgets.

## Opening Homarr

Homarr runs on its own port, **7575**, separate from the Home Assistant interface.

### From the app page

Select **Open web UI** on the app's **Info** tab. This opens
`http://<your-home-assistant-address>:7575` in a new tab. It works on any device on your
home network, including the Home Assistant Companion app on Android and iOS.

### On your phone

In the Companion app, go to **Settings** > **Apps** > **Homarr** and select **Open web UI**.
Homarr opens in your phone's browser; use the browser's **Add to home screen** option to keep
it one tap away.

The address uses the host name you connected to Home Assistant with. When you are away from
home and connect through Home Assistant Cloud or another remote URL, port 7575 is usually not
reachable. Set up [remote access](#remote-access) if you want to use Homarr away from home.

### In the Home Assistant sidebar (optional)

This app does not use Home Assistant's built-in sidebar integration (called *ingress*),
because Homarr cannot run under the changing sub-path that ingress uses. You can still add
Homarr to the sidebar with a **Webpage** dashboard:

1. Go to **Settings** > **Dashboards** and select **Add dashboard**.
2. Choose **Webpage** and enter Homarr's address, for example
   `http://homeassistant.local:7575`.
3. Give it a title such as *Homarr*, pick an icon such as `mdi:view-dashboard-variant`, and
   keep **Show in sidebar** turned on.

Two things to keep in mind:

- The browser loads Homarr directly, so the sidebar entry only works where Homarr's address
  is reachable, normally on your home network.
- If you open Home Assistant over `https://`, the address of the dashboard must use
  `https://` too, or the browser blocks the page. Use your [remote access](#remote-access)
  address in that case.

## Configuration

Example configuration:

```yaml
log_level: info
no_external_connection: false
base_url: https://homarr.example.com
trusted_proxies: 172.30.33.5
env_vars:
  - name: AUTH_SESSION_EXPIRY_TIME
    value: 7d
```

Restart the app after changing any option.

### Option: `log_level`

How much Homarr writes to the **Log** tab: `debug`, `info` (the default), `warn` or `error`.
Use `debug` only while you track down a problem; it is very verbose.

### Option: `no_external_connection`

Turn this on to stop Homarr from contacting the internet on its own: update checks, weather,
location search and RSS feeds stop working. Integrations with services on your own network,
such as Home Assistant or Pi-hole, are not affected.

### Option: `base_url`

The public address Homarr is reached on, such as `https://homarr.example.com`: the scheme and
host name, optionally with a port, but no path. Homarr uses it for secure cookies and origin
checks. Set it when Homarr is behind a reverse proxy that provides HTTPS; leave it empty
otherwise. See [Remote access](#remote-access).

### Option: `trusted_proxies`

A comma-separated list of IP addresses or narrow ranges (CIDR) of reverse proxies in front of
Homarr. Homarr only uses the visitor's address from the `X-Forwarded-For` header of these
proxies, which it needs to rate-limit sign-in attempts per visitor rather than per proxy.

Leave it empty when you do not use a proxy. Use exact addresses: trusting a whole network
lets every device or app in it pretend to be any visitor. To find the address of a proxy that
runs as another Home Assistant app, open that app's **Log** tab or look in **Settings** >
**System** > **Network**; apps get an address in the `172.30.32.0/23` range.

### Option: `env_vars`

Extra [Homarr environment variables](https://homarr.dev/docs/advanced/environment-variables),
each with a `name` and a `value`. They are applied last, so they can also replace a value the
app sets itself. Use them for features without an option of their own, for example signing in
with an OIDC provider such as Authentik or Authelia:

```yaml
env_vars:
  - name: AUTH_PROVIDERS
    value: credentials,oidc
  - name: AUTH_OIDC_ISSUER
    value: https://auth.example.com/application/o/homarr/
  - name: AUTH_OIDC_CLIENT_ID
    value: your-client-id
  - name: AUTH_OIDC_CLIENT_SECRET
    value: your-client-secret
```

Keep `credentials` in `AUTH_PROVIDERS` until you have signed in with the new provider, or you
lock yourself out. Homarr's [single sign-on guide](https://homarr.dev/docs/advanced/single-sign-on)
lists the variables for OIDC and LDAP.

Values are shown in plain text on the **Configuration** tab, to everyone who may manage apps.
Do not override `SECRET_ENCRYPTION_KEY` or the `DB_*` variables unless you move Homarr's data
yourself: Homarr then no longer finds or decrypts what it stored.

### Port

The **Network** section of the **Configuration** tab sets the port Homarr is published on.
Change it if port 7575 is already in use on your server. Clear it to stop publishing Homarr
on your network entirely, for example when a proxy app is the only way in.

## Connecting Home Assistant

Homarr can show and control Home Assistant entities on its boards. Add the integration under
**Integrations** in Homarr's management pages:

1. In Home Assistant, open your profile, select the **Security** tab and create a
   **Long-lived access token**.
2. In Homarr, add a **Home Assistant** integration. Use `http://homeassistant:8123` as the
   URL: other apps reach Home Assistant under that name, whatever address you use in your
   browser. If Home Assistant only accepts HTTPS, use the address its certificate was issued
   for instead, such as `https://home.example.com`.
3. Paste the token and save.

Homarr stores the token encrypted in its database.

## Remote access

To use Homarr away from home, put it behind a reverse proxy that provides HTTPS, such as the
**Cloudflared** or **NGINX Proxy Manager** app, and point the proxy at:

```text
http://<your-home-assistant-ip>:7575
```

Then:

1. Set [`base_url`](#option-base_url) to the public address, for example
   `https://homarr.example.com`.
2. Add the proxy's address to [`trusted_proxies`](#option-trusted_proxies).
3. Use a long, unique password for every account, and consider signing in through an OIDC
   provider with two-factor authentication; see [`env_vars`](#option-env_vars).

Never expose port 7575 directly to the internet without HTTPS.

## Running Homarr commands

Homarr has a command line for maintenance tasks, such as resetting a password or listing
users. The app includes `homarr-cli`, which runs those commands with the app's encryption key
and settings. It needs the **Advanced SSH & Web Terminal** app with *Protection mode* turned
off. In its terminal, run for example:

```bash
docker exec -it "$(docker ps --quiet --filter name=homarr)" homarr-cli users list
```

Replace `users list` with the command you need; `--help` shows them all. Commands that read
the database print their result but do not return to the prompt by themselves; press
**Ctrl+C** once the result is shown. Turn *Protection mode* back on afterwards.

## Backups

The app is included in Home Assistant backups. Homarr is stopped while the backup is made, so
that the database is copied in a consistent state, and starts again afterwards. This takes
well under a minute.

A backup contains everything: the database with your boards, users and integrations, the
encryption key for the integration secrets, trusted certificates and the options. Restoring
the app from a backup restores all of it. The encryption key and the database belong
together: a database restored without its key loses its stored integration secrets.

Uninstalling the app **deletes all Homarr data**. Create a backup first if you might want it
back.

## Updates

The app's version number is the Homarr version it contains. Before you update:

1. Create a backup that includes Homarr. Database changes during an update cannot be undone,
   and Homarr cannot be downgraded without restoring a backup.
2. Read the [Homarr release notes](https://github.com/homarr-labs/homarr/releases) for the
   versions you are skipping.

Homarr upgrades its database automatically on the first start after an update.

## Troubleshooting

Start with the **Log** tab of the app. Homarr, nginx and Redis all write to it, and messages
from the app itself start with `[homarr-app]`.

**The app shows as starting for a long time**
: Homarr runs its database migrations first, which can take a few minutes after an update on
  a Raspberry Pi. The app shows as started once Homarr answers its health check. If it never
  does, the log names the problem.

**"DB migrations failed, aborting startup"**
: Restore the backup made before the update, and
  [open an issue](https://github.com/FaliseDotCom/ha-homarr/issues) with the log.

**The app fails to start right after installation**
: Check that port 7575 is not used by another app, or pick a different port in the
  **Network** section.

**Forgotten password**
: Reset it from the command line, as described in
  [Running Homarr commands](#running-homarr-commands). Homarr prints a new random password:

  ```bash
  docker exec -it "$(docker ps --quiet --filter name=homarr)" homarr-cli reset-password --username admin
  ```

  Replace `admin` with your user name. When no administrator is left, `recreate-admin
  --username admin` creates a new one.

**Integrations or widgets cannot reach a service over HTTPS**
: The service probably uses a self-signed certificate. Add it on Homarr's
  [Certificates](https://homarr.dev/docs/management/certificates) page.

## Security

- Complete the [first start](#first-start) right after installing, before anyone else can.
- Use a long, unique password for every account.
- Only reach Homarr over HTTPS from the internet; see [Remote access](#remote-access).
- Integration secrets are encrypted in the database with a key that is generated on first
  start and stored in the app's private data, never in the options.
- The app has no access to Docker, so Homarr's Docker page is turned off.

## Support

- Problems with this app: [open an issue](https://github.com/FaliseDotCom/ha-homarr/issues).
- Questions about using Homarr: [Homarr documentation](https://homarr.dev/docs/) and
  [Homarr discussions](https://github.com/homarr-labs/homarr/discussions).
