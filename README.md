# z-caddy

[English](./README.md) | [简体中文](./README.zh-CN.md)

Build a custom Caddy Docker image with extra modules, export it as an offline `tar` archive, and load it on another machine with `docker load`.

This repository starts with the Cloudflare DNS module and can be extended by editing `modules.txt`.

## What It Does

- builds a custom Caddy image from the official Caddy release
- bundles the modules listed in `modules.txt`
- exports a Docker archive to `dist/`
- defaults to the latest stable upstream Caddy release
- defaults to `linux/amd64`

## Quick Start

Build the default archive:

```bash
./scripts/build.sh
```

Load it on the target machine:

```bash
docker load -i dist/z-caddy_<caddy-version>_linux-amd64.tar
```

Build ARM64 explicitly:

```bash
./scripts/build.sh --platform linux/arm64
```

Pin a specific Caddy version:

```bash
./scripts/build.sh --caddy-version 2.11.2
```

Local builds are designed to keep only the exported files in `dist/`.

## Module Configuration

Edit `modules.txt`.

- one module per line
- empty lines are ignored
- lines starting with `#` are ignored
- versions can be pinned with `@version`

Example:

```text
github.com/caddy-dns/cloudflare@v0.2.4
github.com/caddyserver/nginx-adapter
```

## Build Script Options

```text
--platform <platform>      Target platform. Default: linux/amd64
--caddy-version <version>  Use a specific Caddy version. Default: latest upstream stable release
--image-name <name>        Image name used inside the exported archive. Default: z-caddy
--image-tag <tag>          Primary image tag inside the exported archive. Default: latest
--modules-file <path>      Module list file. Default: modules.txt
--output-dir <path>        Output directory for tar and checksum files. Default: dist
```

Show help:

```bash
./scripts/build.sh --help
```

## Version Rules

- local builds use the latest stable upstream Caddy release by default
- you can override the version with `--caddy-version`
- published versions follow upstream Caddy versions directly
- Docker Hub uses `latest` and `<caddy-version>` tags

## License

Apache-2.0. See `LICENSE`.
