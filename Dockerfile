# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.27.3-bookworm AS build

# Pin RETICULUM_GO_REF to a commit, tag, or branch for reproducible builds.
ARG RETICULUM_GO_REPO=https://github.com/Quad4-Software/Reticulum-Go.git
ARG RETICULUM_GO_REF=v1.4.1
ARG TARGETOS
ARG TARGETARCH

WORKDIR /src
RUN git init -q . \
 && git remote add origin "${RETICULUM_GO_REPO}" \
 && git fetch --depth 1 origin "${RETICULUM_GO_REF}" \
 && git checkout -q FETCH_HEAD \
 && CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" VERSION="${RETICULUM_GO_REF}" make build

FROM debian:bookworm-slim
LABEL org.opencontainers.image.source="https://github.com/tealblu/rns-docker" \
      org.opencontainers.image.description="Reticulum transport node (Reticulum-Go)" \
      org.opencontainers.image.licenses="MIT AND LicenseRef-Reticulum"

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

COPY LICENSE /usr/share/licenses/rns-docker/LICENSE
COPY --from=build /src/LICENSE /usr/share/licenses/reticulum-go/LICENSE
COPY --from=build /src/NOTICE /usr/share/licenses/reticulum-go/NOTICE

COPY --from=build /src/bin/reticulum-go /usr/local/bin/reticulum-go
# Legacy tool name from Reticulum-Go; the Python rnstatus name is not used.
RUN ln -sf /usr/local/bin/reticulum-go /usr/local/bin/rgostatus

COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY --chmod=755 healthcheck.sh /healthcheck.sh

ENV PATH="/usr/local/bin:$PATH"
VOLUME /root/.reticulum
EXPOSE 4242/tcp

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
  CMD ["/healthcheck.sh"]

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
CMD ["/bin/sh", "-c", "exec reticulum-go --config \"${HOME:-/root}/.reticulum\""]
