# System Components

COCOON consists of several components that work together.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         YOUR SERVER                          │
│                                                              │
│   ┌──────────────┐                                          │
│   │   Your App   │  Makes API calls                         │
│   └──────┬───────┘                                          │
│          │ HTTP                                              │
│          ▼                                                   │
│   ┌──────────────┐                                          │
│   │    Client    │  Docker container                        │
│   └──────┬───────┘                                          │
└──────────┼──────────────────────────────────────────────────┘
           │ RA-TLS (encrypted + attested)
           ▼
┌─────────────────────────────────────────────────────────────┐
│                       COCOON NETWORK                         │
│                                                              │
│   ┌──────────────┐                                          │
│   │    Proxy     │  Routes requests, manages payments       │
│   └──────┬───────┘                                          │
│          │ RA-TLS                                            │
│          ▼                                                   │
│   ┌──────────────┐                                          │
│   │    Worker    │  Executes AI inference (GPU)             │
│   └──────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

## Client

**What it does:**
- Receives HTTP requests from your app (OpenAI-compatible API)
- Connects to proxies via RA-TLS (encrypted and attested)
- Manages payments via TON blockchain
- Returns responses to your app

**Runs:** Docker container (no TDX required)

**HTTP Endpoints:**

| Endpoint | Description |
|----------|-------------|
| `/v1/chat/completions` | Chat completion |
| `/v1/completions` | Text completion |
| `/v1/models` | List models |
| `/stats` | HTML dashboard |
| `/jsonstats` | JSON statistics |

See [API Reference](api-reference.md) for details.

---

## Proxy

**What it does:**
- Accepts client connections
- Selects workers based on model, load, and price
- Routes requests to workers
- Tracks payments between clients and workers
- Commits state to blockchain

**Runs:** TDX VM (Intel Trusted Domain Extensions)

---

## Worker

**What it does:**
- Connects to proxy and advertises model + capacity
- Receives requests from proxy
- Forwards to vLLM inference server
- Returns responses with token counts
- Gets paid via smart contracts

**Runs:** TDX VM with NVIDIA GPU

---

## Router

**What it does:**
- Handles RA-TLS (Remote Attestation TLS)
- Generates TDX certificates with attestation quotes
- Verifies remote attestations during TLS handshake
- Proxies traffic transparently after handshake

**Why separate:**
Inner services (client, proxy, worker) don't need to know about attestation. Router handles all the crypto.

```
┌────────────────────────────────────────────────────────────┐
│                       Container                             │
│                                                             │
│  client-runner ◄──[plain TCP]──► router ◄──[RA-TLS]──► proxy│
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## Seal Server / Client

**What it does:**
- Derives persistent keys for TDX VMs using SGX sealing
- Keys are unique to: physical CPU, TDX image, config, key name
- Same image + same hardware = same key (survives reboots)

Used by proxies and workers to maintain persistent identities.

---

## Smart Contracts

### Root Contract
Network registry containing:
- Proxy list (IP addresses)
- Allowed TDX image hashes
- Allowed model hashes
- Pricing configuration

### CocoonWallet
Your personal wallet for COCOON:
- Signs payment transactions
- Batches up to 4 messages per TON transaction

### ClientContract
Per-client, per-proxy contract:
- Tracks your balance with a specific proxy
- Holds stake (deposit)

### WorkerContract
Per-worker, per-proxy contract:
- Tracks worker's earnings
- Payments signed by proxy, executed by worker

---

## Data Flow

### Request Path

```
App → Client → Router → Proxy → Router → Worker → vLLM
                                                    │
App ← Client ← Router ← Proxy ← Router ← Worker ←──┘
```

### Payment Path

```
1. You fund CocoonWallet
2. CocoonWallet → ClientContract (stake + balance)
3. Per request: Proxy tracks tokens
4. Periodically: ClientContract charged
5. Periodically: WorkerContract paid
6. Worker withdraws to owner wallet
```

---

## Links

- [Docker Deployment](docker.md)
- [API Reference](api-reference.md)
- [Client Setup](client-setup.md)
