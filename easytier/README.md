# EasyTier Landscape Image

Landscape 路由器的 EasyTier overlay 网络出口镜像。将 [EasyTier](https://github.com/EasyTier/EasyTier)（P2P 组网）与 Landscape 的 `redirect_pkg_handler` 打包在一起，作为 Landscape eBPF 流量路由系统的 EasyTier 出口节点。

## 架构

```
Landscape (Host)
    │ eBPF 注入
    ▼
┌─────────────────────────────────┐
│  redirect_pkg_handler           │
│  (接收包 → route 模式)           │
│            │                    │
│     easytier-core               │
│     (WireGuard TUN overlay)     │
│            │                    │
│   EasyTier P2P 网络 (tun0)      │
│            │                    │
│     远程 EasyTier 节点           │
└─────────────────────────────────┘
```

## 支持架构

| 架构 | easytier-core | redirect_pkg_handler |
|------|--------------|---------------------|
| `linux/amd64` | `easytier-linux-x86_64` | `x86_64-musl` |
| `linux/arm64` | `easytier-linux-aarch64` | `aarch64` + `libc6-compat` |

## 快速开始

### 1. 创建 EasyTier 账号

前往 [EasyTier Web 管理端](https://easytier.cn/web#/auth) 注册账号。

### 2. 拉取镜像

```bash
docker pull ghcr.io/wuchen5770/landscape-easytier:latest
```

### 3. docker-compose 使用

```yaml
services:
  easytier:
    image: ghcr.io/wuchen5770/landscape-easytier:latest
    container_name: easytier
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
      - PERFMON
    devices:
      - /dev/net/tun
    sysctls:
      net.ipv4.ip_forward: '1'
      net.ipv6.conf.all.forwarding: '1'
      net.ipv6.conf.all.accept_ra: '2'
      net.ipv6.conf.all.autoconf: '1'
      net.ipv6.conf.default.accept_ra: '2'
    environment:
      - EASYTIER_USERNAME=your-username     # 必填：EasyTier Web 管理端用户名
      - EASYTIER_HOSTNAME=landscape-easytier # 可选：Web 端显示的设备名称
      # - EASYTIER_MACHINE_ID=xxx            # 可选：机器码，不填则自动生成
    volumes:
      - /root/.landscape-router/unix_link/:/ld_unix_link/:ro
    networks:
      easytier-bridge:
        ipv4_address: 172.189.0.10 # 可选：指定容器 IP
    dns:
      - 172.189.0.1 # 设置为 bridge IP 以使用默认流的 DNS 配置

networks:
  easytier-bridge:
    driver: bridge
    enable_ipv6: true
    driver_opts:
      com.docker.network.bridge.name: easytier-br0
    ipam:
      config:
        - subnet: 172.189.0.0/24
          gateway: 172.189.0.1
```

::: warning
网桥中的 `com.docker.network.bridge.name` 一定要设置，否则默认会使用动态网卡名称，重启后网卡名称变动导致 LAN 服务不能正常开启。
:::

### 4. 配置 EasyTier 网络

1. 启动容器：`docker compose up -d`
2. 登录 [EasyTier Web 管理端](https://easytier.cn/web#/auth)
3. 在设备列表找到新设备，点击齿轮图标进入管理
4. 创建或加入网络，配置虚拟子网参数

### 5. 在 Landscape 中创建 Flow

在 Landscape Web 界面中创建一个 Flow，使用此 easytier 容器作为出口，然后配置「目标 IP」规则将指定网段的流量转发到 EasyTier。

## 环境变量

| 变量 | 默认值 | 必填 | 说明 |
|------|--------|------|------|
| `EASYTIER_USERNAME` | — | ✅ | EasyTier Web 管理端用户名 |
| `EASYTIER_HOSTNAME` | 容器 hostname | ❌ | Web 端显示的设备名称 |
| `EASYTIER_MACHINE_ID` | 自动生成 | ❌ | 机器码标识 |

## 自行构建

```bash
# 获取最新版本号
EASYTIER_VER=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep tag_name | cut -d'"' -f4)
LANDSCAPE_VER=$(curl -s https://api.github.com/repos/ThisSeanZhang/landscape/releases/latest | grep tag_name | cut -d'"' -f4)

# 构建
docker build \
  --build-arg EASYTIER_VERSION=$EASYTIER_VER \
  --build-arg LANDSCAPE_VERSION=$LANDSCAPE_VER \
  -t landscape-easytier \
  ./easytier
```

## CI/CD

GitHub Actions 自动构建流程：

1. 获取 Landscape 和 EasyTier 最新 release 版本
2. 构建 `linux/amd64` + `linux/arm64` 双架构镜像
3. 推送到 GHCR，tag 格式为 `<landscape-version>-<easytier-version>` + `latest`

手动触发可在 Actions 页面指定版本覆盖。
