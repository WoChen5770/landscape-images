# ============================================================
# v2rayA + Landscape redirect_pkg_handler (Alpine, multi-arch)
# ============================================================
FROM alpine:3.20

ARG V2RAYA_VERSION=v2.4.11
ARG LANDSCAPE_VERSION=v0.23.0
ARG TARGETARCH

# ---- runtime dependencies ----
RUN apk add --no-cache \
    bash \
    iproute2 \
    iptables \
    iptables-legacy \
    wget \
    ca-certificates \
    coreutils

# ---- v2rayA (amd64->x64, arm64->arm64) ----
# NOTE: GitHub tag has 'v' prefix (v2.4.11) but asset names do NOT (v2raya_linux_x64_2.4.11)
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64)  V2RAYA_ARCH="x64"  ;; \
      arm64)  V2RAYA_ARCH="arm64" ;; \
      *)      echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    V2RAYA_VER="${V2RAYA_VERSION#v}"; \
    wget -q -O /usr/bin/v2raya \
      "https://github.com/v2rayA/v2rayA/releases/download/${V2RAYA_VERSION}/v2raya_linux_${V2RAYA_ARCH}_${V2RAYA_VER}"; \
    wget -q -O /usr/bin/v2raya_core \
      "https://github.com/v2rayA/v2rayA/releases/download/${V2RAYA_VERSION}/v2raya_core_linux_${V2RAYA_ARCH}_${V2RAYA_VER}"; \
    chmod +x /usr/bin/v2raya /usr/bin/v2raya_core

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

# ---- GeoIP / GeoSite data ----
RUN mkdir -p /usr/share/v2raya; \
    wget -q -O /usr/share/v2raya/geosite.dat \
      "https://raw.githubusercontent.com/mzz2017/dist-v2ray-rules-dat/master/geosite.dat"; \
    wget -q -O /usr/share/v2raya/geoip.dat \
      "https://raw.githubusercontent.com/mzz2017/dist-v2ray-rules-dat/master/geoip.dat"

# ---- iptables wrappers ----
COPY iptables.sh   /usr/local/bin/iptables
COPY ip6tables.sh  /usr/local/bin/ip6tables
COPY start.sh      /app/start.sh
RUN chmod +x /usr/local/bin/iptables /usr/local/bin/ip6tables /app/start.sh

# ---- v2rayA config persistence ----
VOLUME /etc/v2raya

# ---- Web UI port ----
EXPOSE 2017

CMD ["/app/start.sh"]
