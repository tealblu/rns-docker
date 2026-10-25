FROM python:3.12-slim AS build
ARG RNS_VERSION
ARG LXMF_VERSION
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir \
    "rns${RNS_VERSION:+==$RNS_VERSION}" \
    "lxmf${LXMF_VERSION:+==$LXMF_VERSION}"

FROM python:3.12-slim
LABEL org.opencontainers.image.source="https://github.com/tealblu/rns-docker" \
      org.opencontainers.image.description="Reticulum transport node (rnsd)" \
      org.opencontainers.image.licenses="NOASSERTION"

RUN apt-get update \
 && apt-get install -y --no-install-recommends tini \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -u 1000 -m rns \
 && mkdir /config && chown rns:rns /config

COPY --from=build /opt/venv /opt/venv
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENV PATH="/opt/venv/bin:$PATH" PYTHONUNBUFFERED=1
USER rns
VOLUME /config
EXPOSE 4242/tcp

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
  CMD rnstatus --config /config >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
CMD ["rnsd", "--config", "/config", "-v"]
