FROM python:3.12-slim AS build
ARG RNS_VERSION
ARG LXMF_VERSION
ENV PYTHONOPTIMIZE=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --no-compile \
    "rns${RNS_VERSION:+==$RNS_VERSION}" \
    "lxmf${LXMF_VERSION:+==$LXMF_VERSION}" \
    "cryptography>=3.4.7"
# cryptography enables Reticulum's OpenSSL-backed Ed25519/X25519. Without it,
# RNS silently falls back to pure Python, which is much slower per packet.
RUN python -m compileall -q -f -o 1 /opt/venv

FROM python:3.12-slim
LABEL org.opencontainers.image.source="https://github.com/tealblu/rns-docker" \
      org.opencontainers.image.description="Reticulum transport node (rnsd)" \
      org.opencontainers.image.licenses="NOASSERTION"

RUN apt-get update \
 && apt-get install -y --no-install-recommends tini \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/venv /opt/venv
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENV PATH="/opt/venv/bin:$PATH" PYTHONUNBUFFERED=1 PYTHONOPTIMIZE=1
VOLUME /root/.reticulum
EXPOSE 4242/tcp

HEALTHCHECK --interval=5m --timeout=15s --start-period=20s \
  CMD rnstatus >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
CMD ["rnsd"]
