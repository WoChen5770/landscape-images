# ============================================================
# EasyTier + Landscape redirect_pkg_handler (Alpine, multi-arch)
# ============================================================
FROM alpine:3.20

ARG EASYTIER_VERSION=v2.6.4
ARG LANDSCAPE_VERSION=v0.23.0
ARG TARGETARCH

# ---- runtime dependencies ----
RUN apk add --no-cache \
    bash \
    iproute2 \
    iptables \
    wireguard-tools \
    curl \
    ca-certificates \
    unzip

# ---- EasyTier core (amd64->x86_64, arm64->aarch64) ----
# Release asset: easytier-linux-x86_64-v2.6.4.zip → contains easytier-core
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64)  ET_ARCH="x86_64"  ;; \
      arm64)  ET_ARCH="aarch64"  ;; \
      *)      echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    wget -q -O /tmp/easytier.zip \
      "https://github.com/EasyTier/EasyTier/releases/download/${EASYTIER_VERSION}/easytier-linux-${ET_ARCH}-${EASYTIER_VERSION}.zip"; \
    unzip -j /tmp/easytier.zip "*/easytier-core" -d /usr/local/bin/; \
    chmod +x /usr/local/bin/easytier-core; \
    rm /tmp/easytier.zip

# ---- Landscape redirect_pkg_handler ----
# amd64: musl binary (native Alpine)
# arm64: glibc binary + libc6-compat
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) \
        wget -q -O /usr/local/bin/redirect_pkg_handler \
          "https://github.com/ThisSeanZhang/landscape/releases/download/${LANDSCAPE_VERSION}/redirect_pkg_handler-x86_64-musl" \
        ;; \
      arm64) \
        apk add --no-cache libc6-compat; \
        wget -q -O /usr/local/bin/redirect_pkg_handler \
          "https://github.com/ThisSeanZhang/landscape/releases/download/${LANDSCAPE_VERSION}/redirect_pkg_handler-aarch64" \
        ;; \
      *) echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    chmod +x /usr/local/bin/redirect_pkg_handler

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
