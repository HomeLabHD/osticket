# 🎫 osticket

A **rootless** container image for [osTicket](https://osticket.com/) — the open-source support-ticketing system — on a current, stock PHP runtime (**osTicket v1.18.x**, **PHP 8.3**). Runs **unprivileged** (uid 1000, arbitrary-UID capable), all-in-one (nginx + php-fpm + cron), with the official **and** community plugin set bundled.

<!-- sf:project:start -->
<!-- sf:project:end -->
<!-- sf:badges:start -->
<!-- sf:badges:end -->
<!-- sf:image:start -->
<!-- sf:image:end -->

### Features

|                        |                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Rootless**           | Runs as uid 1000 — and as *any* uid (OpenShift/hardened-cluster arbitrary-UID)   |
| **All-in-one**         | nginx + php-fpm + osTicket cron, supervised by supervisord, one container        |
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
