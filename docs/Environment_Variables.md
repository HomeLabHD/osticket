# Environment Variables

osTicket here is configured **entirely from the environment** — the container is
stateless (all state lives in the database), and the entrypoint generates
`include/ost-config.php` and runs a one-time, idempotent install on first boot. That
is what lets multiple replicas run against a single database.

Two groups of variables:

- **App contract** — the env-var names your existing deployment already uses, kept
  identical so this image drops in unchanged.
- **Image knobs** — added here for flexibility (listen port, DB port/prefix, PHP tunables).

---

## Networking

| Variable    | Required | Default | Description |
|-------------|----------|---------|-------------|
| `HTTP_PORT` | no       | `8080`  | Port nginx listens on inside the container. |

> ⚠️ **Rootless by default.** This image runs as a **non-root** user (uid 1000), and an
> unprivileged process **cannot bind a port below 1024**. The default `8080` works
> rootless out of the box.
>
> To serve on **port 80** you must do **one** of:
> - run the container as root — Kubernetes `securityContext.runAsUser: 0`, or Docker
>   `--user 0`; **or**
> - grant the bind capability — Kubernetes
>   `securityContext.capabilities.add: ["NET_BIND_SERVICE"]`, or Docker
>   `--cap-add NET_BIND_SERVICE`.
>
> Recommended instead: leave `HTTP_PORT=8080` and map it at the Service/ingress
> (`targetPort: 8080`) — you keep the rootless posture and still front it on 80/443.

`EXPOSE` in the image is `8080` (the default); overriding `HTTP_PORT` changes the actual
listener, and the healthcheck follows it automatically.

---

## Database (required)

| Variable    | Required | Default  | Description |
|-------------|----------|----------|-------------|
| `DB_HOST`   | **yes**  | —        | MySQL/MariaDB host (e.g. `osticket-mariadb-primary`). |
| `DB_PORT`   | no       | `3306`   | Database port. |
| `DB_NAME`   | **yes**  | `osticket` | Database name. |
| `DB_USER`   | **yes**  | —        | Database user. |
| `DB_PASS`   | **yes**  | —        | Database password. **Use a secret.** |
| `DB_PREFIX` | no       | `ost_`   | osTicket table prefix. |

---

## First-run install & admin account

Used **only** on the first boot against an empty database (ignored once installed).

| Variable          | Required | Default | Description |
|-------------------|----------|---------|-------------|
| `INSTALL_NAME`    | **yes**  | —       | Help desk name (e.g. `PrecisionPlanIT Helpdesk`). |
| `INSTALL_EMAIL`   | **yes**  | —       | Default system email address. |
| `INSTALL_SECRET`  | **yes**  | —       | Secret salt for `ost-config.php`. **Use a secret; stable across replicas.** |
| `ADMIN_USER`      | **yes**  | —       | Initial admin username. |
| `ADMIN_PASS`      | **yes**  | —       | Initial admin password. **Use a secret.** |
| `ADMIN_EMAIL`     | **yes**  | —       | Admin email. |
| `ADMIN_FIRSTNAME` | no       | `Admin` | Admin first name. |
| `ADMIN_LASTNAME`  | no       | `User`  | Admin last name. |

---

## SMTP (outbound email)

| Variable        | Required | Default | Description |
|-----------------|----------|---------|-------------|
| `SMTP_HOST`     | no       | —       | SMTP server host. If unset, SMTP is not configured. |
| `SMTP_PORT`     | no       | `587`   | SMTP port. |
| `SMTP_USER`     | no       | —       | SMTP username. |
| `SMTP_PASSWORD` | no       | —       | SMTP password. **Use a secret.** |
| `SMTP_FROM`     | no       | —       | From / envelope sender address. |
| `SMTP_TLS`      | no       | `1`     | `1` = use STARTTLS/TLS, `0` = plaintext. |

---

## Runtime

| Variable        | Required | Default            | Description |
|-----------------|----------|--------------------|-------------|
| `TZ`            | no       | `UTC`              | Container timezone (e.g. `America/Los_Angeles`). |

> osTicket cron runs as a **separate CronJob** (see [docs/k8s/cronjob.yaml](k8s/cronjob.yaml)) on its own schedule, **not** in the web container — running it in every replica would race on mailbox fetch.

### Optional PHP tuning

| Variable               | Default | Description |
|------------------------|---------|-------------|
| `PHP_MEMORY_LIMIT`     | `256M`  | PHP `memory_limit`. |
| `PHP_UPLOAD_MAX_SIZE`  | `25M`   | Max attachment / upload size (`upload_max_filesize` + `post_max_size`). |

---

## Example (Kubernetes, rootless, fronted on 8080)

```yaml
env:
  - { name: TZ,            value: America/Los_Angeles }
  - { name: HTTP_PORT,     value: "8080" }          # rootless default
  - { name: DB_HOST,       value: osticket-mariadb-primary }
  - { name: DB_NAME,       value: osticket }
  - { name: DB_USER,       value: osticket }
  - { name: DB_PASS,       valueFrom: { secretKeyRef: { name: osticket-secrets, key: DB_PASS } } }
  - { name: INSTALL_NAME,  value: "PrecisionPlanIT Helpdesk" }
  # …INSTALL_SECRET, ADMIN_*, SMTP_* from the secret…
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
ports:
  - { containerPort: 8080 }
```
