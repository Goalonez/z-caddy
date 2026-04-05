# z-caddy

[English](./README.md) | [简体中文](./README.zh-CN.md)

Custom Caddy images with extra modules.

Use the published Docker image if you just want to run Caddy. Use this repository if you want a reproducible way to build your own image archive with additional modules.

The default module set currently includes Cloudflare DNS.

## Use The Published Image

Pull from Docker Hub:

```bash
docker pull goalonez/z-caddy:latest
```

Example `docker compose`:

```yaml
services:
  z-caddy:
    image: goalonez/z-caddy:latest
    container_name: z-caddy
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./caddy/conf:/etc/caddy
      - ./caddy/data:/data
      - ./caddy/config:/config
    restart: unless-stopped
```

## Build Your Own Archive

Clone the repository and run:

```bash
./scripts/build.sh
```

This builds an offline archive for `linux/amd64` by default and writes files to `dist/`:

```text
dist/z-caddy_<caddy-version>_linux-amd64.tar
```

Load the archive on the target machine:

```bash
docker load -i dist/z-caddy_<caddy-version>_linux-amd64.tar
```

Build `linux/arm64` explicitly:

```bash
./scripts/build.sh --platform linux/arm64
```

Pin a specific Caddy version:

```bash
./scripts/build.sh --caddy-version 2.11.2
```

Local builds are designed to keep only the exported files in `dist/`.

## Modules

Edit `modules.txt` to change the bundled modules.

- one module per line
- empty lines are ignored
- lines starting with `#` are ignored
- versions can be pinned with `@version`

Example:

```text
github.com/caddy-dns/cloudflare@v0.2.4
github.com/caddyserver/nginx-adapter
```

## Build Options

```text
--platform <platform>      Target platform. Default: linux/amd64
--caddy-version <version>  Use a specific Caddy version. Default: latest upstream stable release
--image-name <name>        Image name used inside the exported archive. Default: z-caddy
--image-tag <tag>          Primary image tag inside the exported archive. Default: latest
--modules-file <path>      Module list file. Default: modules.txt
--output-dir <path>        Output directory for exported tar files. Default: dist
```

Show help:

```bash
./scripts/build.sh --help
```

## Versioning

- local builds use the latest stable upstream Caddy release by default
- `--caddy-version` overrides the default version
- published versions follow upstream Caddy versions directly
- Docker Hub publishes `latest` and `<caddy-version>` tags

## License

Apache-2.0. See `LICENSE`.
