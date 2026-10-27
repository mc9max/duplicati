# Duplicati

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/duplicati?utm_campaign=duplicati)

Duplicati is a free, open-source backup client that stores encrypted,
incremental, compressed backups on cloud storage and remote servers —
Amazon S3, Backblaze B2, OneDrive, Google Drive, SFTP, FTP, WebDAV, and
more — with a built-in scheduler, AES-256 client-side encryption, and a
web UI for creating jobs, watching them run, and restoring files. This
template wraps the official `duplicati/duplicati` image (2.4.0.1, MIT)
for one-click deploys on Railway: one service, one volume, no companion
databases.

## Deploy and Host

Click **Deploy on Railway** above. The deploy form has one generated
field — the web UI login password, generated at deploy time. On first
boot the wrapper maps Railway's injected `PORT` to Duplicati's web
service port, pins all state to the persistent volume, and seeds demo
source files so you can prove a backup cycle immediately. Open the
public URL, sign in with the generated `DUPLICATI__WEBSERVICE_PASSWORD`
(find it in the service variables after deploy), add a backup with
source `/data/source` and a local-folder destination of
`/data/backups`, run it, and restore a file to prove the cycle. Then
point Duplicati at real destinations (S3, B2, SFTP, WebDAV, OneDrive)
from the UI — credentials are entered there, never in the template.

## Why Deploy

- **Real backups, not a demo.** AES-256 encryption, deduplication,
  incremental backups, compression, and a scheduler, so backups happen
  on a schedule instead of when someone remembers a command.
- **Every backend Duplicati supports.** Local disk, S3, Backblaze B2,
  Azure, GCS, SFTP, FTP, WebDAV, OneDrive, Google Drive — configured in
  the UI, no config files, no credentials baked into the image.
- **One lightweight service.** A single .NET server process; it idles on
  a fraction of a vCPU and a few hundred MB of RAM, spending CPU only
  while a backup, verify, or restore job runs. It fits Railway's
  smallest tiers for a personal backup console.
- **Restore from the browser.** Browse any backup version and download
  or restore individual files without touching a terminal.
- **Prove it before trusting it.** The seeded `/data/source` demo files
  let you run a full backup → restore cycle minutes after deploy.

## Common Use Cases

- A scheduled off-site backup console: S3 or B2 destinations backing up
  app data on a cron schedule with retention and verification.
- A personal snapshot browser: import an existing Duplicati backup
  configuration and browse/restore versions from the browser.
- A backup watchdog: scheduled jobs with email/notification reports
  when a job fails, so a silent backup failure gets noticed.
- A staging area for data that lives on the Railway volume itself: a
  local-backend repository at `/data/backups` for quick restores of app
  data (see Honest limitations — this is not off-site backup).

## Configuration

The deploy form has one generated field. The wrapper consumes exactly
these variables; everything else is configured in the Duplicati UI
after first run.

| Variable | Default | What it does |
| --- | --- | --- |
| `PORT` | injected by Railway | Mapped by `entrypoint.sh` to `DUPLICATI__WEBSERVICE_PORT`. Duplicati does not read `PORT` itself. |
| `DUPLICATI__WEBSERVICE_PASSWORD` | `${{secret(32)}}` (generated) | Web UI login password. Duplicati has no sign-up form; without this, first launch generates a random password nobody can know. Find the generated value in the service variables after deploy. |
| `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` | `*` (baked in Dockerfile) | Hostnames allowed to reach the UI. Duplicati rejects hostname-based origins by default, which would block the Railway public domain. Override with your exact domain(s), semicolon-separated, to lock this down. |
| `DUPLICATI__WEBSERVICE_PORT` | set from `PORT` by the wrapper | Port the web service binds. Do not set directly — the wrapper overwrites it from `PORT` on every boot. |
| `DUPLICATI__WEBSERVICE_INTERFACE` | `any` (official image Docker default, re-applied by the wrapper) | Bind interface. `any` lets Railway's edge reach the server; `localhost` would block it. |
| `DUPLICATI__SERVER_DATAFOLDER` | `/data` | Server database (job definitions, settings, state) on the Railway volume, so restarts keep everything. Upstream's own default is also `/data` in the official image; the wrapper pins it explicitly. |
| `DUPLICATI__DISABLE_DB_ENCRYPTION` | `true` (official image Docker default, re-applied by the wrapper) | Disables deriving the settings-DB key from the machine serial number, which changes when a container moves and would make the database inaccessible. Set to `false` plus `SETTINGS_ENCRYPTION_KEY` (min 8 chars, alphanumeric) to encrypt the settings database — keep that key, or the database is unrecoverable. |
| `SETTINGS_ENCRYPTION_KEY` | unset | Settings-database encryption key. Only effective with `DUPLICATI__DISABLE_DB_ENCRYPTION=false`. Not the UI login password. |
| `TZ` | container default (UTC) | Timezone used to evaluate backup schedules. The UI shows times in your browser's zone, but schedules evaluate in container time — set `TZ` if you want schedules in another zone. |

Upstream settings baked into the wrapper (not template variables):
server binary `duplicati-server` from the pinned image, datafolder
`/data`, demo source `/data/source`, local destination `/data/backups`.

### Deployment Dependencies

- Railway plan with persistent volumes (any paid tier; Duplicati idles
  small and spends CPU only while jobs run).
- One volume (`duplicati-data`, mounted at `/data`). No databases, no
  Redis, no workers.
- A public domain (Railway-provided is fine) for the web UI.
- For real off-site backups, storage-backend credentials (S3/B2/SFTP/
  WebDAV/OneDrive), entered in the Duplicati UI — never in the template.

### Honest limitations

- A local-folder destination on the same Railway volume protects
  against accidental deletion, not against losing the volume itself.
  Real disaster recovery means a second, off-site destination.
- Duplicati on Railway backs up data reachable from the container:
  the volume's `/data/source` demo folder, other services' data only
  via a destination those services can write, or remote backends you
  configure in the UI. It is not a host-level agent for your laptop.
