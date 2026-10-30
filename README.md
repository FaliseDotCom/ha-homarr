# Homarr for Home Assistant

[![Add repository to Home Assistant][repository-badge]][repository-url]
![Homarr 2.10.0][homarr-shield]
![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
[![License: MIT][license-shield]](LICENSE)

Run [Homarr](https://homarr.dev/), the sleek, modern dashboard for your home lab, as a Home
Assistant app. Homarr brings your services together on boards you arrange in the browser,
with widgets for media servers, downloads, DNS blockers, calendars, weather and Home
Assistant entities.

## Features

- Homarr with its bundled SQLite database and Redis; no separate database app needed.
- The encryption key for Homarr's stored secrets is generated and kept for you.
- All data is included in Home Assistant backups.
- Options for the log level, internet access and reverse proxies, plus extra environment
  variables for features such as OIDC or LDAP sign-in.
- `homarr-cli` runs Homarr's command line inside the app, for example to reset a password.
- Uses the Home Assistant time zone.
- Opens from the app page, the Home Assistant Companion app, or a sidebar dashboard.
- Runs on `amd64` and `aarch64` (Raspberry Pi 4 and 5).

## Installation

Select the button above, or add the repository by hand:

1. In Home Assistant, go to **Settings** > **Apps** > **Install app**.
2. Open the three-dots menu in the top-right corner and select **Repositories**.
3. Add `https://github.com/FaliseDotCom/ha-homarr` and select **Add**.
4. Find **Homarr** in the app store and select **Install**.

Then follow the [app documentation](homarr/DOCS.md) to start Homarr and create your
administrator account. The same documentation is shown on the app's **Documentation** tab in
Home Assistant.

## Apps in this repository

| App                | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| [Homarr](homarr/)  | A sleek, modern dashboard for your home lab and its services.  |

## Contributing

Bug reports and pull requests are welcome. [Development](.docs/development.md) explains how
the app works and how to test changes, and [Releasing](.docs/releasing.md) covers updating to
a new Homarr version.

The app is shell scripts, YAML and a Dockerfile on top of the official Homarr image. Pull
requests should follow these conventions:

- **Formatting:** two spaces per indentation level, and in shell scripts `then` and `do` and
  function braces on their own line, as in the existing code. `.editorconfig` sets the basics
  for most editors.
- **Documentation:** every shell function has a short comment describing what it does,
  unless its name says it all.
- **Checks:** shell scripts pass [ShellCheck](https://www.shellcheck.net/).
  [Development](.docs/development.md#1-lint) shows how to run it with Docker.
- **User-facing changes:** update [`homarr/DOCS.md`](homarr/DOCS.md) and add an entry to
  [`homarr/CHANGELOG.md`](homarr/CHANGELOG.md).

## AI coding guidelines

None of the language skills (`php`, `phpstan`, `wordpress`, `javascript`, `svelte`, `css`)
apply to this repository: it holds no application code of its own, only shell scripts, YAML
and a Dockerfile. AI coding assistants follow the global formatting rules, the shell style of
`homarr/run.sh`, and run ShellCheck after changing a script.

## License

The files in this repository are released under the [MIT License](LICENSE), except for
`homarr/icon.png` and `homarr/logo.png`. Homarr itself is licensed under the
[Apache License 2.0](https://github.com/homarr-labs/homarr/blob/main/LICENSE) and is not
affiliated with this project.

The Homarr name and the icon images (`homarr/icon.png` and `homarr/logo.png`, resized from
Homarr's own logo) belong to the Homarr project. They are used only to identify the app, and
remain under the Homarr project's terms.

[repository-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FFaliseDotCom%2Fha-homarr
[homarr-shield]: https://img.shields.io/badge/Homarr-2.10.0-blue.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[license-shield]: https://img.shields.io/badge/license-MIT-green.svg
