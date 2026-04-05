# z-caddy

[English](./README.md) | [简体中文](./README.zh-CN.md)

带扩展模块的 Caddy 镜像。

如果你只是想直接运行 Caddy，直接拉取已发布的 Docker 镜像即可。这个仓库的价值在于：当你需要加入更多模块时，可以用统一、可复现的方式自己构建镜像和离线 tar 包。

当前默认集成的模块是 Cloudflare DNS。

## 直接使用已发布镜像

从 Docker Hub 拉取：

```bash
docker pull goalonez/z-caddy:latest
```

`docker compose` 示例：

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

## 自己构建离线包

拉取仓库后执行：

```bash
./scripts/build.sh
```

默认会构建 `linux/amd64` 离线包，并输出到 `dist/`：

```text
dist/z-caddy_<caddy-version>_linux-amd64.tar
dist/z-caddy_<caddy-version>_linux-amd64.tar.sha256
```

在目标机器上导入：

```bash
docker load -i dist/z-caddy_<caddy-version>_linux-amd64.tar
```

显式构建 `linux/arm64`：

```bash
./scripts/build.sh --platform linux/arm64
```

显式指定 Caddy 版本：

```bash
./scripts/build.sh --caddy-version 2.11.2
```

本地构建默认只保留 `dist/` 里的产物文件。

## 模块配置

修改 `modules.txt` 即可。

- 一行一个模块
- 空行会忽略
- `#` 开头的行会忽略
- 可以通过 `@version` 固定模块版本

示例：

```text
github.com/caddy-dns/cloudflare@v0.2.4
github.com/caddyserver/nginx-adapter
```

## 构建参数

```text
--platform <platform>      目标平台，默认：linux/amd64
--caddy-version <version>  指定 Caddy 版本，默认：官方最新稳定版
--image-name <name>        导出包内使用的镜像名，默认：z-caddy
--image-tag <tag>          导出包内使用的主标签，默认：latest
--modules-file <path>      模块清单文件，默认：modules.txt
--output-dir <path>        tar 和校验文件输出目录，默认：dist
```

查看帮助：

```bash
./scripts/build.sh --help
```

## 版本规则

- 本地构建默认跟随 Caddy 官方最新稳定版
- `--caddy-version` 可以显式覆盖默认版本
- 发布版本直接跟随上游 Caddy 版本
- Docker Hub 使用 `latest` 和 `<caddy-version>` 两类标签

## 许可证

Apache-2.0，见 `LICENSE`。
