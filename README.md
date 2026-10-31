# rns-docker

[![Build](https://img.shields.io/github/actions/workflow/status/tealblu/rns-docker/publish.yml?color=pink)](https://github.com/tealblu/rns-docker/actions/workflows/publish.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-tealblu%2Frns--docker-pink?logo=github)](https://github.com/tealblu/rns-docker/pkgs/container/rns-docker)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-pink)](#tags)
[![License](https://img.shields.io/github/license/tealblu/rns-docker?color=pink)](LICENSE)

Docker image for running a [Reticulum](https://reticulum.network) transport node using
[Reticulum-Go](https://github.com/Quad4-Software/Reticulum-Go).

> **Experimental upstream:** Reticulum-Go is wire-compatible with Python RNS, but
> upstream still considers it experimental and it may lag the reference
> implementation. Test interop before relying on it for production transport.

## Quick start

```yaml
services:
  rnsd:
    image: ghcr.io/tealblu/rns-docker:latest
    container_name: rnsd
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./reticulum:/root/.reticulum # optional
```

```sh
docker compose up -d
docker logs rnsd
```

On first start a default config is written to `./reticulum/config`. Edit it and
restart the container to apply changes. Or mount your own reticulum folder in
[the same format that rnsd expects](https://reticulum.network/manual/using.html).
Reticulum-Go reads the same INI shape as Python RNS.

## Configuration

Everything Reticulum stores lives in the mounted directory: `config`, `storage/`
(including your transport identity), and any custom interfaces.

The default config enables transport, an `AutoInterface`, and a TCP server. The
following variables change what gets generated, and only apply when no config
file exists yet:

| Variable | Default | Description |
| --- | --- | --- |
| `RNS_ENABLE_TRANSPORT` | `True` | Sets `enable_transport` |
| `RNS_LOGLEVEL` | `4` | Sets `loglevel` (0 to 7) |
| `RNS_TCP_PORT` | `4242` | Port for the TCP server interface |

Copy `.env.example` to `.env` to set these for Compose.

Reticulum-Go defaults to `~/.reticulum-go`, but the image passes
`--config /root/.reticulum` explicitly so the volume layout stays the same as
previous versions of this image.

## Networking

`AutoInterface` finds peers on your LAN using link-local multicast, which doesn't
work through Docker's bridge network, so `network_mode: host` must be used if you
want to use `AutoInterface` functionality.

If you only need TCP, you can use bridge mode instead:

```yaml
    ports:
      - "4242:4242"
```

Remove the `AutoInterface` block from your config in that case, otherwise it logs
a warning about not being able to autoconfigure.

## Serial and RNode devices

Pass the device through to the container:

```yaml
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
```

## Health check

The container reports healthy once the Reticulum-Go status command can reach the
running instance. Check it with `docker ps`, or run it yourself:

```sh
docker exec rnsd reticulum-go status -config /root/.reticulum
# or the installed legacy name
docker exec rnsd rgostatus -config /root/.reticulum
```

## Building

```sh
git clone https://github.com/tealblu/rns-docker
cd rns-docker
docker build -t rns-docker .
```

The image is built from Reticulum-Go source and cross-compiled for the target
platform. Pin the upstream revision with `RETICULUM_GO_REF` (commit, tag, or
branch; default `v1.4.1`):

```sh
docker build --build-arg RETICULUM_GO_REF=v1.4.1 -t rns-docker .
```

Images are built for `linux/amd64` and `linux/arm64`. The publish workflow
rebuilds weekly from the latest upstream release tag.

## Reticulum-Go notes

- The binary is a single multi-tool. Tools are subcommands, for example
  `reticulum-go status`, `reticulum-go id`, and `reticulum-go path`.
- Landlock/seccomp sandboxing is enabled by default. Under Docker's default
  seccomp profile the daemon logs `Unshare(CLONE_NEWNS) failed` and soft-fails;
  it continues to run. Add `enable_sandbox = no` under `[reticulum]` in
  `./reticulum/config` to silence the message, at the cost of that extra layer.
- Upstream project and documentation:
  <https://github.com/Quad4-Software/Reticulum-Go>.

## Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest build from the most recent upstream Reticulum-Go release |
| `vX.Y.Z` | Build from that upstream Reticulum-Go release tag |

## License

The files in this repository are available under the [MIT License](LICENSE).

Reticulum-Go and Reticulum itself are distributed under their own licenses. Read
them before redistributing images built from this repo:
[Reticulum-Go license](https://github.com/Quad4-Software/Reticulum-Go/blob/master/LICENSE).
