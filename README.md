# rns-docker

[![Build](https://github.com/tealblu/rns-docker/actions/workflows/publish.yml/badge.svg)](https://github.com/tealblu/rns-docker/actions/workflows/publish.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-tealblu%2Frns--docker-pink?logo=github)](https://github.com/tealblu/rns-docker/pkgs/container/rns-docker)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-pink)](#tags)
[![License](https://img.shields.io/github/license/tealblu/rns-docker)](LICENSE)

Docker image for running a [Reticulum](https://reticulum.network) transport node (`rnsd`).

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

On first start a default config is written to `./reticulum/config`. Edit it and restart the container to apply changes. Or mount your own reticulum folder in [the same format that rnsd expects](https://reticulum.network/manual/using.html).

## Configuration

Everything Reticulum stores lives in the mounted directory: `config`, `storage/` (including your transport identity), and any custom interfaces.

The default config enables transport, an `AutoInterface`, and a TCP server. The following variables change what gets generated, and only apply when no config file exists yet:

| Variable | Default | Description |
| --- | --- | --- |
| `RNS_ENABLE_TRANSPORT` | `True` | Sets `enable_transport` |
| `RNS_LOGLEVEL` | `4` | Sets `loglevel` (0 to 7) |
| `RNS_TCP_PORT` | `4242` | Port for the TCP server interface |

See the [Reticulum manual](https://reticulum.network/manual/interfaces.html) for the full list of interface options.

## Networking

`AutoInterface` finds peers on your LAN using link-local multicast, which doesn't work through Docker's bridge network, so `network_mode: host` must be used if you want to use `AutoInterface` functionality.

If you only need TCP, you can use bridge mode instead:

```yaml
    ports:
      - "4242:4242"
```

Remove the `AutoInterface` block from your config in that case, otherwise it logs a warning about not being able to autoconfigure.

## Serial and RNode devices

Pass the device through to the container:

```yaml
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
```

## Health check

The container reports healthy once `rnstatus` can reach the running instance. Check it with `docker ps`, or run it yourself:

```sh
docker exec rnsd rnstatus
```

## Building

```sh
git clone https://github.com/tealblu/rns-docker
cd rns-docker
docker build -t rns-docker .
```

To pin versions, pass `--build-arg RNS_VERSION=1.5.7` (and `LXMF_VERSION` if you want). Images are built for `linux/amd64` and `linux/arm64`, and rebuilt weekly to pick up new RNS releases as well as whenever the base image is updated.

## License

The files in this repository are available under the [MIT License](LICENSE).

Reticulum itself is distributed under its own [license](https://github.com/markqvist/Reticulum/blob/master/LICENSE). Read it before redistributing images built from this repo.
