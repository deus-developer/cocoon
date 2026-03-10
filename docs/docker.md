# Docker Deployment

Run a COCOON client in Docker to access decentralized AI inference.

## Architecture

```
Client (container) → Router (container) → Proxy → Worker (TEE)
```

The router and client run as separate containers connected via a Docker network with static IPs. The client sends inference requests through the router, which handles RA-TLS attestation and routes to proxies in the COCOON network.

**Important:** The client connects to the router by IP address (not hostname), so Docker Compose uses a static subnet (10.100.0.0/24) with fixed IPs.

## Quick Start

```bash
git clone https://github.com/TelegramMessenger/cocoon.git
cd cocoon/docker
cp .env.example .env
nano .env  # Set COCOON_OWNER_ADDRESS and COCOON_NODE_WALLET_KEY
docker compose up -d
```

Check status:
```bash
docker compose logs -f
curl http://localhost:10000/jsonstats | jq .
```

## Supported Platforms

- `linux/amd64`

## Docker Compose

The default `docker-compose.yml` runs two services:

| Service | Container | IP | Description |
|---------|-----------|-----|-------------|
| `router` | `cocoon-router` | 10.100.0.10 | SOCKS5 proxy with RA-TLS |
| `client` | `cocoon-client` | 10.100.0.11 | HTTP API server |

### Build from source

```bash
cd docker
docker compose build
docker compose up -d
```

### Production (pre-built images)

```bash
cd docker
docker compose -f docker-compose.prod.yml up -d
```

## Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `COCOON_OWNER_ADDRESS` | Yes | — | Your TON wallet address |
| `COCOON_NODE_WALLET_KEY` | Yes | — | Ed25519 private key, base64 |
| `COCOON_VERBOSITY` | No | `3` | Log level: 0-4 |
| `COCOON_PROXY_CONNECTIONS` | No | `1` | Number of proxy connections |
| `COCOON_HTTP_ACCESS_HASH` | No | — | API auth token |
| `COCOON_ROUTER_POLICY` | No | `any` | `any` (non-TDX) or `tdx` (production) |
| `COCOON_ROUTER_PORT` | No | `8116` | Router listen port |
| `COCOON_CHECK_PROXY_HASHES` | No | `0` | Proxy hash verification (0/1) |
| `COCOON_ROOT_CONTRACT_ADDRESS` | No | mainnet | Override root contract address |

Generate wallet key:
```bash
openssl rand -base64 32
```

## Funding

Find your wallet address:
```bash
curl http://localhost:10000/jsonstats | jq '.wallet.address'
```

Send TON to this address. Minimum: **2.1 TON**.

## API Usage

```bash
curl -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3-0.6B", "messages": [{"role": "user", "content": "Hello!"}]}'
```

## Monitoring

```bash
docker compose logs -f client
docker compose logs -f router
curl http://localhost:10000/jsonstats | jq .
curl -s http://localhost:10000/jsonstats | jq '.wallet.balance / 1e9'
```

## Building Locally

```bash
# Build both images
docker build --target router -t cocoon-router -f docker/Dockerfile .
docker build --target client -t cocoon-client -f docker/Dockerfile .
```

## CI/CD

GitHub Actions builds and publishes `cocoon-router` and `cocoon-client` images on push to `main` and version tags.

### Setup

1. Create DockerHub access token: hub.docker.com → Account Settings → Security → New Access Token

2. Add to GitHub repository (Settings → Secrets and variables → Actions):
   - Variable: `DOCKERHUB_USERNAME`
   - Secret: `DOCKERHUB_TOKEN`

3. Push:
```bash
git tag v1.0.0
git push origin v1.0.0
```

## Next Steps

- [API Reference](api-reference.md)
- [Client Setup](client-setup.md)
- [Architecture](architecture.md)
