# v2rayA Landscape Image

Landscape 路由器的 v2rayA 代理出口镜像。将 v2rayA（代理客户端）与 Landscape 的 `redirect_pkg_handler` 打包在一起，作为 Landscape eBPF 流量路由系统的代理出口节点。

## 架构

```
Landscape (Host)
    │ eBPF 注入
    ▼
┌─────────────────────────────────┐
│  redirect_pkg_handler           │
│  (接收包 → fwmark 0x1)          │
│            │                    │
│   ip rule + route table 100/106 │
│            ▼                    │
│  v2rayA TProxy (:12345)        │
│            │                    │
│       远程代理服务器              │
└─────────────────────────────────┘
```

## 支持架构

| 架构 | v2rayA | redirect_pkg_handler |
|------|--------|---------------------|
| `linux/amd64` | `v2raya_linux_x64` | `x86_64-musl` |
| `linux/arm64` | `v2raya_linux_arm64` | `aarch64` + `libc6-compat` |

## 快速开始

### 拉取镜像

```bash
docker pull ghcr.io/wuchen5770/v2raya-landscape:latest
```

### docker-compose 使用

```yaml
services:
  v2raya-exit:
    image: ghcr.io/wuchen5770/v2raya-landscape:latest
    container_name: v2raya-exit
    privileged: true
    restart: unless-stopped
    sysctls:
      - net.ipv4.conf.lo.accept_local=1
    cap_add:
      - NET_ADMIN
      - BPF
      - PERFMON
    volumes:
      - /root/.landscape-router/unix_link/:/ld_unix_link/:ro
      - v2raya-config:/etc/v2raya
    ports:
      - "2017:2017"
    labels:
      - "ld_flow_edge=true"

volumes:
  v2raya-config:
```

### 配置代理

1. 启动容器：`docker compose up -d`
2. 浏览器访问 `http://<host-ip>:2017`
3. 在 v2rayA Web UI 中添加代理节点
4. 开启透明代理 → TProxy 模式，端口保持默认 `12345`
5. 在 Landscape 中配置域名规则，将流量导向此容器

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `IPTABLES_MODE` | (自动) | iptables 模式：`nftables` / `legacy` / 默认 |
| `LAND_PROXY_SERVER_PORT` | `12345` | redirect_pkg_handler 的 TProxy 目标端口 |
| `LAND_PROXY_SERVER_ADDR` | `0.0.0.0` | redirect_pkg_handler 的 TProxy 目标地址 |
| `LAND_REDIRECT_LOG_LEVEL` | `INFO` | redirect_pkg_handler 日志级别 |

## 自行构建

```bash
# 获取最新版本号
V2RAYA_VER=$(curl -s https://api.github.com/repos/v2rayA/v2rayA/releases/latest | grep tag_name | cut -d'"' -f4)
LANDSCAPE_VER=$(curl -s https://api.github.com/repos/ThisSeanZhang/landscape/releases/latest | grep tag_name | cut -d'"' -f4)

# 构建
docker build \
  --build-arg V2RAYA_VERSION=$V2RAYA_VER \
  --build-arg LANDSCAPE_VERSION=$LANDSCAPE_VER \
  -t v2raya-landscape \
  ./v2raya
```

## CI/CD

推送到 main 分支或手动触发 GitHub Actions 会自动：
1. 获取 Landscape 和 v2rayA 最新 release 版本
2. 构建 linux/amd64 + linux/arm64 双架构镜像
3. 推送到 GHCR，tag 为 Landscape 版本号 + `latest`

手动触发可在 Actions 页面指定 v2rayA 版本覆盖。
