# syntax=docker/dockerfile:1.7

ARG CADDY_VERSION=2.11.2

FROM caddy:${CADDY_VERSION}-builder AS builder

ARG MODULES_FILE=modules.txt

COPY ${MODULES_FILE} /tmp/modules.txt

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eu; \
    module_args=""; \
    while IFS= read -r line || [ -n "$line" ]; do \
        line="${line#"${line%%[![:space:]]*}"}"; \
        line="${line%"${line##*[![:space:]]}"}"; \
        case "$line" in \
            ''|'#'*) continue ;; \
        esac; \
        module_args="$module_args --with $line"; \
    done < /tmp/modules.txt; \
    if [ -n "$module_args" ]; then \
        # shellcheck disable=SC2086 \
        xcaddy build --output /usr/bin/caddy-custom $module_args; \
    else \
        xcaddy build --output /usr/bin/caddy-custom; \
    fi

FROM caddy:${CADDY_VERSION}

COPY --from=builder /usr/bin/caddy-custom /usr/bin/caddy
