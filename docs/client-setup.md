# Client Setup

This guide explains the wallet system and configuration options.

## Two-Wallet System

COCOON uses two wallets:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Your Tonkeeper Wallet          CocoonWallet                │
│  ════════════════════          ════════════                 │
│                                                             │
│  Address: UQAxxxxx...          Address: EQByyyyy...         │
│  Key: in Tonkeeper             Key: COCOON_NODE_WALLET_KEY  │
│                                                             │
│  You own this ─────────────────── Controlled by COCOON      │
│                                                             │
│                  Funds flow:                                │
│                                                             │
│  1. You send TON ────────────────> CocoonWallet             │
│  2. CocoonWallet ────────────────> pays for inference       │
│  3. On close: remaining funds ───> back to your wallet      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Your Personal Wallet (Tonkeeper)

- Your regular TON wallet
- You control the private key
- COCOON never accesses this key
- Refunds go here when you close contracts

### CocoonWallet

- A smart contract created for COCOON operations
- Address computed from your wallet address + `COCOON_NODE_WALLET_KEY`
- COCOON client uses this to pay for inference
- You fund it, COCOON spends it automatically

## Configuration

### Required Settings

| Setting | Description | How to get |
|---------|-------------|------------|
| `COCOON_OWNER_ADDRESS` | Your Tonkeeper wallet address | Copy from Tonkeeper |
| `COCOON_NODE_WALLET_KEY` | Key for CocoonWallet | `openssl rand -base64 32` |

### Optional Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `COCOON_VERBOSITY` | 3 | Log level (0=fatal, 4=debug) |
| `COCOON_HTTP_ACCESS_HASH` | — | API authentication token |

## Payment Flow

### 1. Fund Your CocoonWallet

After starting the client, find the CocoonWallet address:

```bash
curl http://localhost:10000/jsonstats | jq -r '.wallet.address'
```

Send TON from Tonkeeper to this address.

### 2. Automatic Payments

When you make inference requests:
1. Client connects to proxy
2. Proxy tracks token usage
3. Periodically charges your CocoonWallet
4. Proxy pays workers

### 3. Closing

When you stop using COCOON:
```bash
curl "http://localhost:10000/request/close?proxy=<proxy_address>"
```

Remaining balance returns to your Tonkeeper wallet.

## Minimum Balance

| Account | Minimum | Recommended |
|---------|---------|-------------|
| CocoonWallet | 2.1 TON | 5 TON |

If balance drops below 2.1 TON, requests will fail.

## Troubleshooting

### "Balance too low"

Send more TON to your CocoonWallet address.

### "Failed to connect to proxy"

1. Check network connectivity
2. Check logs: `docker logs cocoon`

### Lost wallet key

If you lose `COCOON_NODE_WALLET_KEY`:
1. Generate a new key
2. Start fresh with a new CocoonWallet
3. Old CocoonWallet funds return to your Tonkeeper after ~24 hours

## Security

1. **Never share `COCOON_NODE_WALLET_KEY`** — it controls your CocoonWallet
2. **Use unique keys per deployment** — don't reuse across instances
3. **Set `COCOON_HTTP_ACCESS_HASH`** — protects your API
