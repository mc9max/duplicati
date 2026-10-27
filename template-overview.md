[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/duplicati?utm_campaign=duplicati)

# Deploy and Host

Duplicati is a free, open-source backup client that stores encrypted,
incremental, compressed backups on cloud storage and remote servers.
Deploy it on Railway in one click: one service, one volume, no
companion databases. The deploy form has one generated field — the web
UI login password, generated at deploy time and visible in the service
variables. Open the public URL after deploy, sign in with that password,
and run a backup of the seeded `/data/source` demo files to a local
destination at `/data/backups` to prove the full backup → restore cycle
before pointing Duplicati at real destinations.

## About Hosting

Hosting Duplicati on Railway means the backup server runs as a single
.NET process on Railway's infrastructure, with its server database,
demo source files, and local backup destination on a persistent volume.
There are no companion services to babysit: no Postgres to tune, no
Redis to feed, no workers to scale. The wrapper maps Railway's injected
`PORT` to Duplicati's web service port on every boot and pins the
server datafolder to `/data` on the volume, so restarts and redeploys
keep every backup job, schedule, and setting. Railway terminates TLS at
the edge, and Duplicati's plain HTTP listener serves the full UI and
API.

## Why Deploy

- **Real backups, not a demo.** AES-256 encryption, deduplication,
  incremental backups, compression, and a scheduler, so backups happen
  on a schedule instead of when someone remembers a command.
- **Every backend Duplicati supports.** Local disk, S3, Backblaze B2,
  Azure, GCS, SFTP, FTP, WebDAV, OneDrive, Google Drive — configured in
  the UI, no credentials baked into the image.
- **Lightweight by design.** One server process; it idles small and
  spends CPU only while a backup, verify, or restore job runs.
- **Restore from the browser.** Browse any backup version and download
  or restore individual files without a terminal.

## Common Use Cases

- A scheduled off-site backup console: S3 or B2 destinations backing up
  app data on a schedule with retention and verification.
- A personal snapshot browser: import an existing Duplicati backup
  configuration and browse/restore versions from the browser.
- A backup watchdog: scheduled jobs with failure reports, so a silent
  backup failure gets noticed.
- A staging area for data on the Railway volume itself: a local-backend
  repository for quick restores of app data (not a substitute for
  off-site backup).

## Dependencies for

Duplicati on Railway depends on one persistent volume and a public
domain. Everything else — port mapping, datafolder placement, demo
source seeding, healthchecks — is handled by the wrapper at boot.

### Deployment Dependencies

- Railway plan with persistent volumes (any paid tier; Duplicati idles
  small and spends CPU only while jobs run).
- One volume (`duplicati-data`, mounted at `/data`). No databases, no
  Redis, no workers.
- A public domain (Railway-provided is fine) for the web UI.
- For real off-site backups, storage-backend credentials (S3/B2/SFTP/
  WebDAV/OneDrive), entered in the Duplicati UI — never in the template.

## Configuration

| Variable | Default | What it does |
| --- | --- | --- |
| `PORT` | injected by Railway | Mapped by the wrapper to Duplicati's web service port. |
| `DUPLICATI__WEBSERVICE_PASSWORD` | `${{secret(32)}}` (generated) | Web UI login password; find the generated value in the service variables after deploy. |
| `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` | `*` (baked) | Hostnames allowed to reach the UI; override with exact domain(s) to lock down. |
| `DUPLICATI__WEBSERVICE_INTERFACE` | `any` | Bind interface (official image Docker default). |
| `DUPLICATI__SERVER_DATAFOLDER` | `/data` | Server database on the volume. |
| `DUPLICATI__DISABLE_DB_ENCRYPTION` | `true` | Official image Docker default; set `false` plus `SETTINGS_ENCRYPTION_KEY` to encrypt the settings database. |
| `TZ` | container default (UTC) | Timezone for schedule evaluation. |
