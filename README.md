# 🎫 osticket

A **rootless** container image for [osTicket](https://osticket.com/) — the open-source support-ticketing system. Runs **unprivileged** (uid 1000, arbitrary-UID capable): nginx + php-fpm under a minimal rootless init (tini); osTicket cron runs as a separate CronJob. Ships with the official **and** community plugin set bundled.

<!-- sf:project:start -->
[![GitHub](https://img.shields.io/badge/GitHub-source-181717?logo=github)](https://github.com/HomeLabHD/osticket) [![GitLab](https://img.shields.io/badge/GitLab-source-FC6D26?logo=gitlab)](https://gitlab.prplanit.com/HomeLabHD/osticket) [![Last Commit](https://img.shields.io/github/last-commit/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/commits) [![Open Issues](https://img.shields.io/github/issues/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/issues) [![Open PRs](https://img.shields.io/github/issues-pr/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/pulls) [![Contributors](https://img.shields.io/github/contributors/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/graphs/contributors)
<!-- sf:project:end -->
<!-- sf:badges:start -->
[![build](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/build.svg)](https://gitlab.prplanit.com/HomeLabHD/osticket/-/pipelines) [![license](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/license.svg)](https://github.com/HomeLabHD/osticket/blob/main/LICENSE) [![release](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/release.svg)](https://github.com/HomeLabHD/osticket/releases) ![updated](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/updated.svg) [![donate](https://img.shields.io/badge/donate-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/T6T41IT163) [![sponsor](https://img.shields.io/badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/HomeLabHD)
<!-- sf:badges:end -->
<!-- sf:image:start -->
[![Docker](https://img.shields.io/badge/Docker-hlhd%2Fosticket-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/osticket) [![pulls](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/pulls.svg)](https://hub.docker.com/r/hlhd/osticket)
<!-- sf:image:end -->

## Image contents

Base:
<!-- sf:contents-base:start -->
[![php 8.3.33](https://img.shields.io/badge/php-8.3.33-0078D4?style=flat)](https://hub.docker.com/_/php)
<!-- sf:contents-base:end -->

Packages:
<!-- sf:contents-apk:start -->
[![$PHPIZE_DEPS](https://img.shields.io/badge/$PHPIZE__DEPS-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=%24PHPIZE_DEPS) [![.build-deps](https://img.shields.io/badge/.build--deps-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=.build-deps) [![.plugins](https://img.shields.io/badge/.plugins-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=.plugins) [![c-client](https://img.shields.io/badge/c--client-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=c-client) [![composer](https://img.shields.io/badge/composer-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=composer) [![curl](https://img.shields.io/badge/curl-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=curl) [![freetype](https://img.shields.io/badge/freetype-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=freetype) [![freetype-dev](https://img.shields.io/badge/freetype--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=freetype-dev) [![gettext](https://img.shields.io/badge/gettext-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=gettext) [![gettext-dev](https://img.shields.io/badge/gettext--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=gettext-dev) [![git](https://img.shields.io/badge/git-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=git) [![icu-dev](https://img.shields.io/badge/icu--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=icu-dev) [![icu-libs](https://img.shields.io/badge/icu--libs-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=icu-libs) [![imap-dev](https://img.shields.io/badge/imap--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=imap-dev) [![krb5-dev](https://img.shields.io/badge/krb5--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=krb5-dev) [![krb5-libs](https://img.shields.io/badge/krb5--libs-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=krb5-libs) [![libintl](https://img.shields.io/badge/libintl-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libintl) [![libjpeg-turbo](https://img.shields.io/badge/libjpeg--turbo-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libjpeg-turbo) [![libjpeg-turbo-dev](https://img.shields.io/badge/libjpeg--turbo--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libjpeg-turbo-dev) [![libldap](https://img.shields.io/badge/libldap-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libldap) [![libpng](https://img.shields.io/badge/libpng-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libpng) [![libpng-dev](https://img.shields.io/badge/libpng--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libpng-dev) [![libzip](https://img.shields.io/badge/libzip-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libzip) [![libzip-dev](https://img.shields.io/badge/libzip--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libzip-dev) [![mariadb-client](https://img.shields.io/badge/mariadb--client-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=mariadb-client) [![nginx](https://img.shields.io/badge/nginx-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=nginx) [![oniguruma](https://img.shields.io/badge/oniguruma-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=oniguruma) [![oniguruma-dev](https://img.shields.io/badge/oniguruma--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=oniguruma-dev) [![openldap-dev](https://img.shields.io/badge/openldap--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=openldap-dev) [![openssl-dev](https://img.shields.io/badge/openssl--dev-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=openssl-dev) [![su-exec](https://img.shields.io/badge/su--exec-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=su-exec) [![tini](https://img.shields.io/badge/tini-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=tini) [![tzdata](https://img.shields.io/badge/tzdata-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=tzdata)
<!-- sf:contents-apk:end -->

### Features

|                        |                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Rootless**           | Runs as uid 1000 — and as *any* uid (OpenShift/hardened-cluster arbitrary-UID)   |
| **Minimal init**       | nginx + php-fpm under a minimal rootless init (tini); osTicket cron runs as a separate CronJob |
| **Current**            | osTicket `1.18.x` on stock `php:8.3-fpm-alpine` — no resurrected vendor base      |
| **Plugins bundled**    | Official set (LDAP, OAuth, storage) + community (Slack, Teams, Archiver, …)       |
| **Env-driven install** | Idempotent first-boot install from env → multiple stateless replicas             |
| **Observability**      | Logs to stdout (Loki); php-fpm/nginx status endpoints (VictoriaMetrics)           |
| **Flexible port**      | `HTTP_PORT` (default 8080, rootless); 80 needs root or `NET_BIND_SERVICE`         |

### Documentation

| Topic | |
|-------|-|
| [Environment Variables](docs/Environment_Variables.md) | Full env reference — database, install/admin, SMTP, runtime, port |

---

## Installation

Pull the image (**ghcr** primary, Docker Hub mirror) or build it yourself:

```bash
docker pull ghcr.io/homelabhd/osticket:latest
# or
docker pull docker.io/hlhd/osticket:latest
```

```bash
git clone https://github.com/HomeLabHD/osticket
cd osticket
docker build -t hlhd/osticket .
```

osTicket needs a MySQL/MariaDB database and is configured **entirely from the environment** — see [Environment Variables](docs/Environment_Variables.md). The container serves on `HTTP_PORT` (default `8080`); front it on 80/443 at your ingress/Service.

## Contributing

- Fork the repository
- Submit Pull Requests / Merge Requests
- [File issues](../../issues/new) with image tag, run/compose command, and environment details

## Credits

* Powered by [osTicket](https://github.com/osTicket/osTicket) — the actively-maintained open-source ticketing system

## Disclaimer

> The Software provided hereunder ("Software") is licensed "as-is," without warranties of any kind — express, implied, or telepathically transmitted. The developer makes no promises about functionality, performance, compatibility, security, or availability. Not liable if your help desk becomes self-aware and starts closing your tickets as "won't fix," if env-driven auto-install summons an admin account you didn't ask for, or if running it rootless gives you such a smug sense of security that you forget to back up your database.

> Any positive experiences are owed entirely to the brilliant folks behind osTicket and the unstoppable force that is the Open Source community. The developer claims no credit for anything that actually goes right.

## License

osTicket is distributed under the [GPL-2.0](https://github.com/osTicket/osTicket/blob/develop/LICENSE.txt) license. This packaging is maintained by HomeLabHD.
