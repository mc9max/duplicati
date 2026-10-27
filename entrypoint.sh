#!/bin/sh
# Duplicati entrypoint for Railway.
#
# Why this script exists (read before changing it):
# - Duplicati does NOT read Railway's injected PORT. It binds
#   DUPLICATI__WEBSERVICE_PORT (upstream default 8200). This script
#   maps PORT -> DUPLICATI__WEBSERVICE_PORT on every boot, so
#   Railway's edge always has something to reach, on whatever port
#   Railway assigns.
# - The official image stores all server configuration in /data, which
#   is exactly where the single Railway volume is mounted, so no
#   datafolder remapping is needed beyond pinning it explicitly to
#   /data (DUPLICATI__SERVER_DATAFOLDER) so a future upstream default
#   change cannot silently move state off the volume.
# - The official image's Docker defaults are re-applied explicitly here
#   because this script replaces the image entrypoint:
#   DUPLICATI__WEBSERVICE_INTERFACE=any (the Docker network interface
#   is guarded by Railway's edge, not by binding to localhost) and
#   DUPLICATI__DISABLE_DB_ENCRYPTION=true (the image's documented
#   Docker default: it avoids deriving the settings-DB key from the
#   machine serial number, which changes when a container moves and
#   would make the database inaccessible). Operators who want an
#   encrypted settings database can set DUPLICATI__DISABLE_DB_ENCRYPTION=false
#   plus SETTINGS_ENCRYPTION_KEY in the service variables.
# - DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES defaults to * via the
#   Dockerfile ENV (see Dockerfile for why). A service variable of the
#   same name overrides it.
# - Railway allows exactly one volume per service, so the demo source
#   folder and the local backup destination live as subdirectories of
#   the same /data mount (/data/source, /data/backups) instead of
#   separate mounts. The demo source is seeded only when empty, so
#   restarts never overwrite user files.
# - First-run login is the generated DUPLICATI__WEBSERVICE_PASSWORD
#   template variable (find it in the service variables after deploy).
#   There is no sign-up form and no email step: Duplicati's first
#   launch would otherwise generate a random password that nobody can
#   know, so the password MUST come from the template variable.
# - The upstream server binary is exec'd intact so signal handling and
#   the image's own env defaulting stay as upstream intended; this
#   script only adds the Railway mappings above.
set -e

PORT="${PORT:-8200}"
export DUPLICATI__WEBSERVICE_PORT="${PORT}"
export DUPLICATI__WEBSERVICE_INTERFACE="${DUPLICATI__WEBSERVICE_INTERFACE:-any}"
export DUPLICATI__DISABLE_DB_ENCRYPTION="${DUPLICATI__DISABLE_DB_ENCRYPTION:-true}"
export DUPLICATI__SERVER_DATAFOLDER="${DUPLICATI__SERVER_DATAFOLDER:-/data}"

mkdir -p /data/source /data/backups

# Duplicati 2.4 refuses to start if its data folder already exists with
# group/other permissions (Railway mounts volumes 755). The wrapper
# creates this folder tree itself on first boot, so restricting it is
# safe and required: without this chmod the server crash-loops with
# "The data folder '/data/' does not have secure permissions".
# This is the manual equivalent of Duplicati's
# 'duplicati-configure secure-datafolder' command.
chmod 700 /data

if [ -z "$(ls -A /data/source 2>/dev/null)" ]; then
  cat > /data/source/demo-notes.txt <<'EOF'
Duplicati on Railway — demo source files
=========================================
These files exist so you can prove a full backup -> restore cycle
right after deploy, before pointing Duplicati at real data.

1. Open the Duplicati web UI and sign in with the generated
   DUPLICATI__WEBSERVICE_PASSWORD from the service variables.
2. Add a backup with source /data/source and destination
   /data/backups (a local folder destination).
3. Run the backup, then restore one file and confirm its contents.

When you are ready for real backups, add your own source folders and
a real destination (S3, B2, SFTP, WebDAV, OneDrive, and more are all
supported in the UI) — and keep the demo files or delete them.
EOF
  echo "Railway demo file 1 — backed up by Duplicati." > /data/source/demo-file-1.txt
  echo "Railway demo file 2 — restore this to prove the cycle works." > /data/source/demo-file-2.txt
fi

echo "[duplicati] listening on 0.0.0.0:${PORT}, datafolder=/data, source=/data/source, backups=/data/backups"
exec duplicati-server
