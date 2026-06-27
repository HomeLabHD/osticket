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

## Secrets injection

The secret-class variables — `DB_PASS`, `INSTALL_SECRET`, `ADMIN_PASS`, `SMTP_PASSWORD` —
can be provided **without putting them in the environment**, and the right method differs
by platform:

- **Docker:** each of those accepts a **`<VAR>_FILE`** form pointing at a file (Docker
  `secrets:` at `/run/secrets/*`, or a bind-mount). The entrypoint reads the file into the
  variable at startup and the file value wins — e.g. `DB_PASS_FILE=/run/secrets/db_pass`. So
  the secret never lands in the container env or the compose file. See
  [docs/docker/docker-compose.yaml](docker/docker-compose.yaml). The `_FILE` set is an
  explicit allowlist of the known secrets (not "any var"), to keep the surface tight.
- **Kubernetes:** use `secretKeyRef` (a `Secret`, ideally fed by ExternalSecret/Vault) →
  env. The secret never appears in the manifest. See [docs/k8s/](k8s/).

Either way the secret stays out of plaintext env and out of source control.

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
| `OSTICKET_ENFORCE_EXTERNAL_CRON` | no | `1` | Pin osTicket's AutoCron **off** on every boot, so web replicas never fetch mail on page loads. Set `0` to opt out (you then own single-fetcher safety). |

> osTicket cron runs as a **separate CronJob** (see [docs/k8s/cronjob.yaml](k8s/cronjob.yaml)) on its own schedule, **not** in the web container — running it in every replica would race on mailbox fetch.
>
> **Why the admin-UI "Enable AutoCron" toggle won't stick:** osTicket has no distributed
> lock around mail fetch, so AutoCron + multiple replicas is an unsupported topology
> (concurrent fetch → duplicate tickets). With `OSTICKET_ENFORCE_EXTERNAL_CRON=1` (default)
> the entrypoint re-asserts `enable_auto_cron=0` on **every** boot and logs it loudly — so
> the single external CronJob stays the only scheduled worker. Set the var to `0` only if
> you run exactly one web replica and want web-triggered cron.

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
