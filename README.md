# rns-docker

[![Build](https://img.shields.io/github/actions/workflow/status/tealblu/rns-docker/publish.yml?color=pink)](https://github.com/tealblu/rns-docker/actions/workflows/publish.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-tealblu%2Frns--docker-pink?logo=github)](https://github.com/tealblu/rns-docker/pkgs/container/rns-docker)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-pink)](#tags)
[![License](https://img.shields.io/github/license/tealblu/rns-docker?color=pink)](LICENSE)

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

On first start a default config is written to `./reticulum/config`. Until you edit it, it is treated as auto-generated and rewritten from the environment variables below on every start, so changes to those variables apply without deleting the volume. As soon as the file differs from what the image generated, it is treated as your config and is never overwritten. Delete `./reticulum/config` and `./reticulum/.config.generated` to return to auto-generation.

You can also mount your own reticulum folder in [the same format that rnsd expects](https://reticulum.network/manual/using.html). If you omit the volume entirely, nothing persists and the container starts from a freshly generated config every time, which is handy for demoing env-var changes.

## Configuration

Everything Reticulum stores lives in the mounted directory: `config`, `storage/` (including your transport identity), any custom interfaces, and the `.config.generated` snapshot used to detect local edits.

The default config enables transport, an `AutoInterface`, and a TCP server. The following variables change what gets generated. They apply to the auto-generated config on every restart, and are ignored once you have edited the config:

| Variable | Default | Description |
| --- | --- | --- |
| `RNS_ENABLE_TRANSPORT` | `True` | Sets `enable_transport` |
| `RNS_LOGLEVEL` | `2` | Sets `loglevel` (0 to 7) |
| `RNS_TCP_PORT` | `4242` | Port for the TCP server interface |
| `RNS_TCP_ENABLED` | `yes` | Enable or disable the TCP server interface |
| `RNS_AUTO_INTERFACE` | `yes` | Enable or disable the `AutoInterface` |
| `RNS_AUTO_DEVICES` | none | Comma-separated interfaces to use for discovery, e.g. `eth0` |
| `RNS_AUTO_IGNORED_DEVICES` | none | Comma-separated interfaces to exclude, e.g. `docker0,br0` |

See the [Reticulum manual](https://reticulum.network/manual/interfaces.html) for the full list of interface options.

With the default `loglevel = 2`, rnsd only logs warnings and errors. Set `RNS_LOGLEVEL=3` for startup and notice messages, or `4` for informational output.

## Networking

`AutoInterface` finds peers on your LAN using link-local multicast, which doesn't work through Docker's bridge network, so `network_mode: host` must be used if you want to use `AutoInterface` functionality.

If you only need TCP, you can use bridge mode instead:

```yaml
    ports:
      - "4242:4242"
```

Remove the `AutoInterface` block from your config in that case, otherwise it logs a warning about not being able to autoconfigure.

With host networking, `AutoInterface` also sees Docker bridges, VPNs, and other virtual interfaces. Each interface it adopts gets its own listener threads and discovery timers, so limiting discovery reduces both CPU and thread count. Add its name to the interface block in `./reticulum/config`:

```ini
[[Default Interface]]
  type = AutoInterface
  enabled = yes
  devices = eth0
```

Use `ignored_devices = docker0, br0, veth0` to exclude interfaces instead. List available names with `ip -brief link`. If you leave the config auto-generated, set `RNS_AUTO_DEVICES=eth0` or `RNS_AUTO_IGNORED_DEVICES=docker0,br0,veth0` and restart the container instead.

`AutoInterface` only adopts interfaces that have an IPv6 link-local address, so most plain Docker bridges are skipped automatically. Bridges with IPv6 enabled, Tailscale, and similar interfaces are not.

## Serial and RNode devices

Pass the device through to the container:

```yaml
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
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
