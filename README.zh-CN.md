# VPS Stack（Nginx + V2Ray + Certbot）

[![GitHub](https://img.shields.io/github/license/SaltPepperVinegar/nginx-vless-ws-proxy-in-docker)](https://github.com/SaltPepperVinegar/nginx-vless-ws-proxy-in-docker/blob/master/LICENSE)

[English](README.md)

本仓库用于部署一个小型 VPS 站点栈，包含：

- `nginx`：从 `./html` 提供静态内容，并反向代理 VLESS-over-WebSocket 入口。
- `v2ray`（v2fly-core）：提供 VLESS 入站。
- `certbot`：处理 Let's Encrypt 的 HTTP-01 证书签发与续期。

推荐通过 `./start.sh` 启动。该脚本会渲染模板、初始化 TLS（如有需要），并启动整套服务。

## 环境要求

- 一个你控制的域名，A/AAAA 记录指向此 VPS 公网 IP。
- 对外开放端口 `80` 和 `443`，用于 HTTP-01 签发与 HTTPS 流量。
- 需要 Docker 和 Docker Compose。安装与设置请参考：[Docker Engine](https://docs.docker.com/get-docker/) 与 [Docker Compose](https://docs.docker.com/compose/install/)。

## 快速开始

1. 从示例创建 `.env`：

```bash
cp .env.example .env
```

2. 填写 `.env` 中的配置：

- `DOMAIN` - 你的公网域名（A/AAAA 记录必须指向此 VPS）。
- `LE_EMAIL` - Let's Encrypt 使用的邮箱。
- `VLESS_UUID` - VLESS 客户端 UUID（生成方法见下文）。
- `VLESS_PATH` - WebSocket 路径（`.env.example` 中有默认值）。
- `V2RAY_PORT` - v2ray 内部端口（`.env.example` 中有默认值）。

3. 启动服务栈：

```bash
./start.sh
```

脚本将会：

- 从 `./v2ray/config.json.template` 渲染 `./v2ray/config.json`。
- 从 `./clash/clash.yaml.template` 渲染 `./clash/clash.yaml`。
- 如果 `./certs/live/$DOMAIN` 中已有证书，会直接启动完整服务。
- 否则先启动仅 HTTP 的临时 nginx 配置，请求证书后切换为完整 TLS 配置。

## 服务说明

- `nginx`（容器名 `nginx-blog`）
  - 端口：`80`、`443`。
  - 提供 `./html` 中的静态文件。
  - 使用 `./certs` 中的证书终止 TLS。
  - 将 `VLESS_PATH` 代理到 `v2ray` 的 `V2RAY_PORT`。

- `v2ray`（容器名 `v2ray`）
  - 基于 WebSocket 的 VLESS 入站，路径为 `VLESS_PATH`。
  - 配置渲染到 `./v2ray/config.json`。

- `certbot`（容器名 `certbot`）
  - 每 12 小时执行一次 `certbot renew`，续期后重载 nginx。

- `certbot-init`（profile `init`）
  - 在尚无证书时执行一次性签发。

## 文件与模板

- `docker-compose.yml` - 栈定义。
- `start.sh` - 引导脚本。
- `nginx/site.acme.conf.template` - ACME 签发用的 HTTP-only nginx 配置。
- `nginx/site.full.conf.template` - 完整 TLS + 代理配置。
- `v2ray/config.json.template` - V2Ray 配置模板。
- `clash/clash.yaml.template` - Clash 客户端配置模板输出。

## 生成 VLESS_UUID

VLESS 需要一个 UUID。任意 RFC4122 UUID 都可用。

常见生成方式：

```bash
# Linux/macOS（通常已有 uuidgen）
uuidgen

# Python（若没有 uuidgen）
python - << 'PY'
import uuid
print(uuid.uuid4())
PY
```

将生成的 UUID 填入 `.env` 的 `VLESS_UUID`。

## 使用 clash.yaml

`./start.sh` 会生成可直接导入的 Clash 配置：`./clash/clash.yaml`。

包含内容：

- 一个指向 `https://$DOMAIN` 和 `VLESS_PATH` 的 VLESS-over-WebSocket 代理。
- 已开启 TLS，与服务端配置一致。

使用方法：

1. 运行 `./start.sh` 生成 `./clash/clash.yaml`。
1. 下载 `./clash/clash.yaml` 到客户端设备。
1. 在 Clash 中导入该文件并启用。

如果你修改了 `DOMAIN`、`VLESS_UUID` 或 `VLESS_PATH`，请重新运行 `./start.sh` 以重新渲染 `./clash/clash.yaml`。

## 备注

- `start.sh` 会使用 `sudo docker compose`，请使用具备 sudo 权限的用户运行。
- 初次签发证书前请确认 DNS 已生效。
- 仅在 TLS 启用后，WebSocket 入口才会通过 `https://$DOMAIN$VLESS_PATH` 暴露。
