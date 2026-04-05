#!/usr/bin/env bash

set -euo pipefail

LATEST_RELEASE_URL="${CADDY_LATEST_RELEASE_URL:-https://github.com/caddyserver/caddy/releases/latest}"

if ! command -v curl >/dev/null 2>&1; then
  printf 'Missing required command: curl\n' >&2
  exit 1
fi

effective_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "$LATEST_RELEASE_URL")"
version="${effective_url##*/}"
version="${version#v}"

case "$version" in
  ''|*[!0-9A-Za-z.-]*)
    printf 'Failed to resolve the latest Caddy version from %s\n' "$LATEST_RELEASE_URL" >&2
    exit 1
    ;;
esac

printf '%s\n' "$version"
