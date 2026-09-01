# 🎫 osticket

A **rootless** container image for [osTicket](https://osticket.com/) — the open-source support-ticketing system. Runs **unprivileged** (uid 1000, arbitrary-UID capable): nginx + php-fpm under a minimal rootless init (tini); osTicket cron runs as a separate CronJob. Ships with the official **and** community plugin set bundled.

<!-- sf:project:start -->
[![GitHub](https://img.shields.io/badge/GitHub-mirror-181717?logo=github)](https://github.com/HomeLabHD/osticket) [![GitLab](https://img.shields.io/badge/GitLab-source-FC6D26?logo=gitlab)](https://gitlab.prplanit.com/HomeLabHD/osticket) [![license](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/license.svg)](https://github.com/HomeLabHD/osticket/blob/main/LICENSE) [![Open Issues](https://img.shields.io/github/issues/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/issues) [![Open PRs](https://img.shields.io/github/issues-pr/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/pulls) [![Contributors](https://img.shields.io/github/contributors/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/graphs/contributors) [![donate](https://img.shields.io/badge/donate-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/T6T41IT163) [![sponsor](https://img.shields.io/badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/HomeLabHD)
<!-- sf:project:end -->
<!-- sf:badges:start -->
[![release](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/release.svg)](https://github.com/HomeLabHD/osticket/releases) [![build](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/build.svg)](https://gitlab.prplanit.com/HomeLabHD/osticket/-/pipelines) [![Last Commit](https://img.shields.io/github/last-commit/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/commits) [![StageFreight](https://img.shields.io/badge/StageFreight-0.10.0--dev+b4514dc-310937?logo=readthedocs&logoColor=white)](https://stagefreight.prplanit.com)
<!-- sf:badges:end -->
<!-- sf:image:start -->
[![GHCR](https://img.shields.io/badge/GHCR-homelabhd%2Fosticket-181717?logo=github&logoColor=white)](https://github.com/HomeLabHD/osticket/pkgs/container/osticket) [![Docker](https://img.shields.io/badge/Docker-hlhd%2Fosticket-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/osticket) [![pulls](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/pulls.svg)](https://hub.docker.com/r/hlhd/osticket) [![Harbor](https://img.shields.io/badge/Harbor-hlhd%2Fosticket-60b932)](https://cr.pcfae.com/harbor/projects)

[![latest](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/release-latest.svg)](https://github.com/HomeLabHD/osticket/pkgs/container/osticket) ![updated](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/release-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/release-size.svg)](https://github.com/HomeLabHD/osticket/pkgs/container/osticket) [![latest-dev](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/dev-latest.svg)](https://github.com/HomeLabHD/osticket/pkgs/container/osticket) ![updated](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/dev-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/scribe/dev-size.svg)](https://github.com/HomeLabHD/osticket/pkgs/container/osticket)
<!-- sf:image:end -->

### Documentation

| Topic | |
|-------|-|
| [Environment Variables](docs/Environment_Variables.md) | Full env reference — database, install/admin, SMTP, runtime, port |

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

## Image contents

<details>
<summary>Base image &amp; installed packages (click to expand)</summary>

Base Image:
<!-- sf:contents-base:start -->
[![php 8.3.33](https://img.shields.io/badge/php-8.3.33-0078D4?style=flat)](https://hub.docker.com/_/php)
<!-- sf:contents-base:end -->

Packages (apk):
<!-- sf:contents-apk:start -->
[![c-client](https://img.shields.io/badge/c--client-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=c-client) [![curl](https://img.shields.io/badge/curl-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=curl) [![freetype](https://img.shields.io/badge/freetype-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=freetype) [![gettext](https://img.shields.io/badge/gettext-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=gettext) [![icu-libs](https://img.shields.io/badge/icu--libs-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=icu-libs) [![krb5-libs](https://img.shields.io/badge/krb5--libs-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=krb5-libs) [![libintl](https://img.shields.io/badge/libintl-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libintl) [![libjpeg-turbo](https://img.shields.io/badge/libjpeg--turbo-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libjpeg-turbo) [![libldap](https://img.shields.io/badge/libldap-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libldap) [![libpng](https://img.shields.io/badge/libpng-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libpng) [![libzip](https://img.shields.io/badge/libzip-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=libzip) [![mariadb-client](https://img.shields.io/badge/mariadb--client-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=mariadb-client) [![nginx](https://img.shields.io/badge/nginx-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=nginx) [![oniguruma](https://img.shields.io/badge/oniguruma-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=oniguruma) [![su-exec](https://img.shields.io/badge/su--exec-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=su-exec) [![tini](https://img.shields.io/badge/tini-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=tini) [![tzdata](https://img.shields.io/badge/tzdata-555?style=flat)](https://pkgs.alpinelinux.org/packages?name=tzdata)
<!-- sf:contents-apk:end -->

</details>

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
