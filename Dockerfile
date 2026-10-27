# Duplicati (duplicati/duplicati) wrapper for Railway.
#
# Why each non-default setting exists:
# - FROM pins the official image by tag AND digest:
#   duplicati/duplicati 2.4.0.1 (latest stable, 2026-10-07), multi-arch
#   index digest sha256:e32e280cc30e98ac5cea8d2b339cd19810b1b39e638fb9d39253786630104de0
#   (verified against the Docker Hub registry API; the amd64 manifest is
#   sha256:b37ce0b035cdbf1ed3bf38386cd8f0830a382f8148b02bc3c7861bfa6f711b61).
#   Never :latest: a moving tag would change the backup server under
#   existing backup jobs and config.
# - USER root: Railway mounts persistent volumes root-owned; the server
#   database, backup destinations and demo source all live on /data, so
#   the server must be able to write there without EACCES crash loops.
# - DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES=* is baked in: Duplicati
#   rejects hostname-based origins by default (DNS-rebinding protection),
#   which would block the Railway public domain. A service variable of
#   the same name overrides this for operators who want a locked-down
#   hostname list. The login password still guards the UI.
# - The image's own server binary (duplicati-server) is exec'd through
#   entrypoint.sh, which maps Railway's injected PORT to
#   DUPLICATI__WEBSERVICE_PORT and pins the server datafolder to /data.
#   See entrypoint.sh for the full rationale.
# - No HEALTHCHECK: Railway's external healthcheckPath (/) is the check
#   that matters; an in-container HEALTHCHECK would only duplicate it.
# - No EXPOSE: the server binds Railway's injected PORT via the
#   entrypoint mapping, so a static port declaration would be a lie.
# - No CMD: entrypoint.sh execs duplicati-server itself; nothing
#   depends on the image CMD.
FROM duplicati/duplicati:2.4.0.1@sha256:e32e280cc30e98ac5cea8d2b339cd19810b1b39e638fb9d39253786630104de0
USER root
ENV DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES=*
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
LABEL org.opencontainers.image.source="https://github.com/mc9max/duplicati"
LABEL org.opencontainers.image.title="Duplicati"
LABEL org.opencontainers.image.description="Duplicati backup server (AES-256, incremental, scheduled) wrapped for one-click Railway deploys"
