#!/usr/bin/env bash

set -euo pipefail

DEFAULT_CADDY_VERSION="latest"
DEFAULT_PLATFORM="linux/amd64"
DEFAULT_IMAGE_NAME="z-caddy"
DEFAULT_IMAGE_TAG="latest"
DEFAULT_MODULES_FILE="modules.txt"
DEFAULT_OUTPUT_DIR="dist"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
WORKDIR="$(pwd)"

usage() {
  cat <<'EOF'
Usage: ./scripts/build.sh [options]

Build a custom Caddy image archive that can be imported with docker load.

Options:
  --platform <platform>        Target platform. Default: linux/amd64
  --caddy-version <version>    Caddy version. Default: latest stable upstream release
  --image-name <name>          Docker image name. Default: z-caddy
  --image-tag <tag>            Primary Docker image tag. Default: latest
  --modules-file <path>        Module list file. Default: modules.txt
  --output-dir <path>          Output directory. Default: dist
  -h, --help                   Show this help message

Examples:
  ./scripts/build.sh
  ./scripts/build.sh --platform linux/arm64
  ./scripts/build.sh --image-name goalonez/z-caddy --image-tag latest
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

cleanup_builder() {
  if [ -n "${TEMP_BUILDER_NAME:-}" ]; then
    docker buildx rm --force "$TEMP_BUILDER_NAME" >/dev/null 2>&1 || true
  fi
}

create_temp_builder() {
  TEMP_BUILDER_NAME="z-caddy-$(date +%s)-$$"
  docker buildx create --driver docker-container --name "$TEMP_BUILDER_NAME" >/dev/null
  docker buildx inspect --bootstrap "$TEMP_BUILDER_NAME" >/dev/null
}

resolve_caddy_version() {
  if [ "$CADDY_VERSION" = "latest" ] || [ -z "$CADDY_VERSION" ]; then
    bash "$SCRIPT_DIR/get-latest-caddy-version.sh"
    return
  fi

  printf '%s\n' "$CADDY_VERSION"
}

resolve_path() {
  case "$1" in
    /*)
      printf '%s\n' "$1"
      ;;
    *)
      printf '%s/%s\n' "$WORKDIR" "$1"
      ;;
  esac
}

platform_to_id() {
  printf '%s' "$1" | tr '/' '-'
}

IMAGE_NAME="$DEFAULT_IMAGE_NAME"
IMAGE_TAG="$DEFAULT_IMAGE_TAG"
PLATFORM="$DEFAULT_PLATFORM"
CADDY_VERSION="$DEFAULT_CADDY_VERSION"
MODULES_FILE="$DEFAULT_MODULES_FILE"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --caddy-version)
      CADDY_VERSION="$2"
      shift 2
      ;;
    --image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --image-tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --modules-file)
      MODULES_FILE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_command docker
require_command shasum
require_command date

if ! docker buildx version >/dev/null 2>&1; then
  printf 'docker buildx is required but not available.\n' >&2
  exit 1
fi

if [ ! -f "$MODULES_FILE" ]; then
  printf 'Modules file not found: %s\n' "$MODULES_FILE" >&2
  exit 1
fi

CADDY_VERSION="$(resolve_caddy_version)"

OUTPUT_DIR="$(resolve_path "$OUTPUT_DIR")"
mkdir -p "$OUTPUT_DIR"

IMAGE_BASENAME="${IMAGE_NAME##*/}"
PLATFORM_ID="$(platform_to_id "$PLATFORM")"
ARCHIVE_PATH="$OUTPUT_DIR/${IMAGE_BASENAME}_${CADDY_VERSION}_${PLATFORM_ID}.tar"
CHECKSUM_PATH="${ARCHIVE_PATH}.sha256"
VERSION_TAG="$CADDY_VERSION"

trap cleanup_builder EXIT INT TERM

create_temp_builder

printf 'Building image %s for %s\n' "$IMAGE_NAME" "$PLATFORM"
printf 'Caddy version: %s\n' "$CADDY_VERSION"
printf 'Modules file: %s\n' "$MODULES_FILE"
printf 'Archive path: %s\n' "$ARCHIVE_PATH"

docker buildx build \
  --builder "$TEMP_BUILDER_NAME" \
  --platform "$PLATFORM" \
  --build-arg "CADDY_VERSION=$CADDY_VERSION" \
  --build-arg "MODULES_FILE=$MODULES_FILE" \
  --tag "$IMAGE_NAME:$IMAGE_TAG" \
  --tag "$IMAGE_NAME:$VERSION_TAG" \
  --output "type=docker,dest=$ARCHIVE_PATH" \
  .

shasum -a 256 "$ARCHIVE_PATH" > "$CHECKSUM_PATH"

printf '\nBuild complete.\n'
printf 'Docker archive: %s\n' "$ARCHIVE_PATH"
printf 'Checksum file: %s\n' "$CHECKSUM_PATH"
printf '\nLoad the image with:\n'
printf '  docker load -i %s\n' "$ARCHIVE_PATH"
printf '\nExpected tags after load:\n'
printf '  %s:%s\n' "$IMAGE_NAME" "$IMAGE_TAG"
printf '  %s:%s\n' "$IMAGE_NAME" "$VERSION_TAG"
