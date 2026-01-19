# Docker Deployment

Run a COCOON client in Docker to access decentralized AI inference.

## Architecture

```
Client (Docker) → Router → Proxy → Worker (TEE)
```

The Docker image contains the client and router components. The client sends inference requests through the router, which handles RA-TLS attestation and routes to proxies in the COCOON network.

## Quick Start

### Pre-built Image

```bash
docker pull cocoon/cocoon:latest

docker run -d --name cocoon \
  -e COCOON_OWNER_ADDRESS=UQAe4yPi... \
  -e COCOON_NODE_WALLET_KEY=MKHYgEvP... \
  -p 10000:10000 \
  cocoon/cocoon:latest

curl http://localhost:10000/stats
```

### Docker Compose

```bash
git clone https://github.com/TelegramMessenger/cocoon.git
cd cocoon/docker
cp .env.example .env
nano .env
docker compose up -d
```

## Supported Platforms

- `linux/amd64`
- `linux/arm64`

## Docker Compose Examples

### Basic

```yaml
services:
  cocoon:
    image: cocoon/cocoon:latest
    restart: unless-stopped
    ports:
      - "10000:10000"
    environment:
      - COCOON_OWNER_ADDRESS=${COCOON_OWNER_ADDRESS}
      - COCOON_NODE_WALLET_KEY=${COCOON_NODE_WALLET_KEY}
    volumes:
      - cocoon-data:/data

volumes:
  cocoon-data:
```

### Production

```yaml
services:
  cocoon:
    image: cocoon/cocoon:latest
    restart: unless-stopped
    stop_grace_period: 30s
    ports:
      - "10000:10000"
    environment:
      - COCOON_OWNER_ADDRESS=${COCOON_OWNER_ADDRESS}
      - COCOON_VERBOSITY=${COCOON_VERBOSITY:-3}
      - COCOON_PROXY_CONNECTIONS=${COCOON_PROXY_CONNECTIONS:-1}
    secrets:
      - cocoon_node_wallet_key
    volumes:
      - cocoon-data:/data
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://localhost:10000/jsonstats"]
      interval: 30s
      timeout: 10s
      start_period: 60s
      retries: 3
    logging:
      driver: json-file
      options:
        max-size: 50m
        max-file: "3"

secrets:
  cocoon_node_wallet_key:
    environment: COCOON_NODE_WALLET_KEY

volumes:
  cocoon-data:
```

## Configuration

| Variable | Required | Description |
|----------|----------|-------------|
| `COCOON_OWNER_ADDRESS` | Yes | Your TON wallet address |
| `COCOON_NODE_WALLET_KEY` | Yes | Ed25519 private key, base64 |
| `COCOON_VERBOSITY` | No | Log level: 0-4 (default: 3) |
| `COCOON_PROXY_CONNECTIONS` | No | Number of proxy connections (default: 1) |
| `COCOON_HTTP_ACCESS_HASH` | No | API auth token |

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
docker logs -f cocoon
curl http://localhost:10000/jsonstats | jq .
curl -s http://localhost:10000/jsonstats | jq '.wallet.balance / 1e9'
```

## Building Locally

```bash
docker build -t cocoon -f docker/Dockerfile .

docker buildx build --platform linux/amd64,linux/arm64 \
  -t myuser/cocoon:latest -f docker/Dockerfile --push .
```

## CI/CD

GitHub Actions builds and publishes images on push to `main` and version tags.

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
