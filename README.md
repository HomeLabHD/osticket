# 🎫 osticket

A **rootless** container image for [osTicket](https://osticket.com/) — the open-source support-ticketing system — on a current, stock PHP runtime (**osTicket v1.18.x**, **PHP 8.3**). Runs **unprivileged** (uid 1000, arbitrary-UID capable): nginx + php-fpm under a minimal rootless init (tini); osTicket cron runs as a separate CronJob. Ships with the official **and** community plugin set bundled.

<!-- sf:project:start -->
[![badge/GitHub-source-181717?logo=github](https://img.shields.io/badge/GitHub-source-181717?logo=github)](https://github.com/HomeLabHD/osticket) [![badge/GitLab-source-FC6D26?logo=gitlab](https://img.shields.io/badge/GitLab-source-FC6D26?logo=gitlab)](https://gitlab.prplanit.com/HomeLabHD/osticket) [![badge/upstream-osTicket-0099CC?logo=osticket](https://img.shields.io/badge/upstream-osTicket-0099CC?logo=osticket)](https://github.com/osTicket/osTicket) [![Last Commit](https://img.shields.io/github/last-commit/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/commits) [![Open Issues](https://img.shields.io/github/issues/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/issues) [![Contributors](https://img.shields.io/github/contributors/HomeLabHD/osticket)](https://github.com/HomeLabHD/osticket/graphs/contributors)
<!-- sf:project:end -->
<!-- sf:badges:start -->
[![build](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/badges/build.svg)](https://gitlab.prplanit.com/HomeLabHD/osticket/-/pipelines) [![license](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/badges/license.svg)](https://github.com/osTicket/osTicket/blob/develop/LICENSE.txt) [![release](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/badges/release.svg)](https://github.com/HomeLabHD/osticket/releases) ![updated](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/badges/updated.svg) [![badge/donate-FF5E5B?logo=ko-fi&logoColor=white](https://img.shields.io/badge/donate-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/T6T41IT163) [![badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white](https://img.shields.io/badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/HomeLabHD)
<!-- sf:badges:end -->
<!-- sf:image:start -->
[![badge/ghcr.io-homelabhd%2Fosticket-181717?logo=github](https://img.shields.io/badge/ghcr.io-homelabhd%2Fosticket-181717?logo=github)](https://github.com/HomeLabHD/osticket/pkgs/container/osticket) [![badge/Docker-hlhd%2Fosticket-2496ED?logo=docker&logoColor=white](https://img.shields.io/badge/Docker-hlhd%2Fosticket-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/osticket) [![pulls](https://raw.githubusercontent.com/HomeLabHD/osticket/main/.stagefreight/badges/pulls.svg)](https://hub.docker.com/r/hlhd/osticket)
<!-- sf:image:end -->

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
