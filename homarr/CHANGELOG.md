# Changelog

All notable changes to this app are documented here. The version number is the Homarr
version the app contains; see the
[Homarr releases](https://github.com/homarr-labs/homarr/releases) for changes in Homarr itself.

## 2.12.0

- Homarr 2.12.0. See the [Homarr 2.12.0 release notes](https://github.com/homarr-labs/homarr/releases/tag/v2.12.0).

## 2.11.1

- Homarr 2.11.1. See the [Homarr 2.11.1 release notes](https://github.com/homarr-labs/homarr/releases/tag/v2.11.1).
- Homarr's image now uses Debian instead of Alpine, so the app does too. Your boards, users
  and settings carry over; there is nothing to do.
- Node.js now comes straight from Homarr's image, which has caught up with the security
  releases this app used to add itself.

## 2.10.1

- Homarr 2.10.1. See the [Homarr 2.10.1 release notes](https://github.com/homarr-labs/homarr/releases/tag/v2.10.1).

## 2.10.0

- Homarr 2.10.0. See the [Homarr 2.10.0 release notes](https://github.com/homarr-labs/homarr/releases/tag/v2.10.0).

## 2.7.0

First release.

- Homarr 2.7.0 with its bundled SQLite database and Redis.
- Security updates on top of Homarr's image: Node.js 24.22.1 instead of 24.18.0, and the
  latest Alpine packages, including a fixed zlib.
- Generates and keeps the encryption key for Homarr's stored secrets.
- All data in Home Assistant backups.
- Options for the log level, internet access, the public address behind a proxy, trusted
  proxies and extra environment variables such as OIDC or LDAP sign-in.
- `homarr-cli` runs Homarr's command line inside the app, for example to reset a password.
- Opens through **Open web UI**; English and Dutch option descriptions.
