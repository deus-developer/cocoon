# COCOON Documentation

COCOON is a decentralized AI inference platform on the TON blockchain.

## Quick Start

1. [Docker Deployment](docker.md) — Run a client in 5 minutes
2. [API Reference](api-reference.md) — Make inference requests

## Understanding the System

3. [Client Setup](client-setup.md) — Wallet system and configuration
4. [Components](components.md) — How client, proxy, and worker interact

## Overview

```
Your App
    │
    │ HTTP (OpenAI-compatible)
    ▼
COCOON Client (Docker)
    │
    │ RA-TLS (encrypted + attested)
    ▼
Proxy (TDX VM)
    │
    │ RA-TLS
    ▼
Worker (TDX VM + GPU)
    │
    ▼
vLLM → Response
```

**Key features:**

- **Privacy**: Prompts and responses encrypted end-to-end
- **Verification**: TDX attestation proves genuine execution
- **Payments**: Automatic micropayments via TON blockchain
- **OpenAI-compatible**: Works with existing SDKs and tools

## Example

```bash
curl -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-0.6B",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Links

- [GitHub Repository](https://github.com/TelegramMessenger/cocoon)
- [Website](https://cocoon.org)
- [TON Documentation](https://docs.ton.org/)
