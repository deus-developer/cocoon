# API Reference

The COCOON client exposes an OpenAI-compatible HTTP API.

## Base URL

```
http://localhost:10000
```

## Authentication

If `COCOON_HTTP_ACCESS_HASH` is configured, add it as a query parameter to every request:

```bash
# Without auth (when access_hash not configured)
curl http://localhost:10000/v1/models

# With auth
curl "http://localhost:10000/v1/models?access_hash=your_secret_token"
```

All endpoints support the `access_hash` parameter.

---

## Inference Endpoints

### POST /v1/chat/completions

Chat completion — the primary endpoint for conversational AI.

**Headers:**
```
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `model` | string | **yes** | — | Model identifier (e.g., `Qwen/Qwen3-0.6B`) |
| `messages` | array | **yes** | — | Conversation messages |
| `max_tokens` | integer | no | 1000 | Maximum tokens to generate |
| `temperature` | float | no | 1.0 | Sampling temperature (0.0-2.0). Lower = more deterministic |
| `top_p` | float | no | 1.0 | Nucleus sampling. Alternative to temperature |
| `top_k` | integer | no | -1 | Top-k sampling. -1 = disabled |
| `frequency_penalty` | float | no | 0.0 | Penalize frequent tokens (-2.0 to 2.0) |
| `presence_penalty` | float | no | 0.0 | Penalize tokens already present (-2.0 to 2.0) |
| `repetition_penalty` | float | no | 1.0 | Repetition penalty (1.0 = disabled) |
| `stop` | string or array | no | — | Stop sequences. Generation stops when encountered |
| `stream` | boolean | no | false | Enable streaming responses |
| `n` | integer | no | 1 | Number of completions to generate |
| `seed` | integer | no | — | Random seed for reproducibility |
| `user` | string | no | — | End-user identifier for tracking |

**COCOON-specific fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `max_coefficient` | integer | 4000 | Maximum worker price coefficient you'll accept |
| `timeout` | float | 120 | Request timeout in seconds |
| `enable_debug` | boolean | false | Include timing info in response |
| `request_guid` | string | — | Custom request ID for tracking/debugging |

**Message Object:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `role` | string | **yes** | One of: `system`, `user`, `assistant` |
| `content` | string | **yes** | Message text |

**Example Request:**

```bash
curl -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-0.6B",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ],
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

**Response:**

```json
{
  "id": "chatcmpl-abc123def456",
  "object": "chat.completion",
  "created": 1700000000,
  "model": "Qwen/Qwen3-0.6B",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "The capital of France is Paris."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 8,
    "total_tokens": 33,
    "total_cost": 3300
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique completion identifier |
| `object` | string | Always `chat.completion` |
| `created` | integer | Unix timestamp |
| `model` | string | Model used |
| `choices` | array | Generated completions |
| `choices[].index` | integer | Choice index (0-based) |
| `choices[].message.role` | string | Always `assistant` |
| `choices[].message.content` | string | Generated text |
| `choices[].finish_reason` | string | `stop`, `length`, or `null` |
| `usage` | object | Token usage statistics |

**finish_reason values:**

| Value | Meaning |
|-------|---------|
| `stop` | Natural end or stop sequence reached |
| `length` | max_tokens limit reached |
| `null` | Still generating (streaming only) |

---

### POST /v1/completions

Text completion — generate text from a prompt (non-chat format).

**Request Body:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `model` | string | **yes** | — | Model identifier |
| `prompt` | string or array | **yes** | — | Input text(s) to complete |
| `max_tokens` | integer | no | 1000 | Maximum tokens to generate |
| `temperature` | float | no | 1.0 | Sampling temperature |
| `top_p` | float | no | 1.0 | Nucleus sampling |
| `stop` | string or array | no | — | Stop sequences |
| `stream` | boolean | no | false | Enable streaming |
| `echo` | boolean | no | false | Include prompt in response |
| `suffix` | string | no | — | Text to append after completion |

Plus all COCOON-specific fields from chat completions.

**Example Request:**

```bash
curl -X POST http://localhost:10000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-0.6B",
    "prompt": "The capital of France is",
    "max_tokens": 20,
    "temperature": 0.5
  }'
```

**Response:**

```json
{
  "id": "cmpl-abc123def456",
  "object": "text_completion",
  "created": 1700000000,
  "model": "Qwen/Qwen3-0.6B",
  "choices": [
    {
      "index": 0,
      "text": " Paris. Paris is the largest city in France and serves as the country's political, economic, and cultural center.",
      "finish_reason": "length"
    }
  ],
  "usage": {
    "prompt_tokens": 6,
    "completion_tokens": 20,
    "total_tokens": 26,
    "total_cost": 2600
  }
}
```

---

### GET /v1/models

List all available models in the network.

**Example Request:**

```bash
curl http://localhost:10000/v1/models
```

**Response:**

```json
{
  "object": "list",
  "data": [
    {
      "id": "Qwen/Qwen3-0.6B",
      "object": "model",
      "created": 1700000000,
      "owned_by": "cocoon"
    },
    {
      "id": "Qwen/Qwen3-8B",
      "object": "model",
      "created": 1700000000,
      "owned_by": "cocoon"
    },
    {
      "id": "meta-llama/Llama-3.1-8B-Instruct",
      "object": "model",
      "created": 1700000000,
      "owned_by": "cocoon"
    }
  ]
}
```

---

## Streaming

Add `"stream": true` to receive Server-Sent Events (SSE).

**Request:**

```bash
curl -N -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-0.6B",
    "messages": [{"role": "user", "content": "Count from 1 to 5"}],
    "stream": true
  }'
```

**Response (SSE stream):**

```
data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1700000000,"model":"Qwen/Qwen3-0.6B","choices":[{"index":0,"delta":{"role":"assistant","content":""},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1700000000,"model":"Qwen/Qwen3-0.6B","choices":[{"index":0,"delta":{"content":"1"},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1700000000,"model":"Qwen/Qwen3-0.6B","choices":[{"index":0,"delta":{"content":","},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1700000000,"model":"Qwen/Qwen3-0.6B","choices":[{"index":0,"delta":{"content":" 2"},"finish_reason":null}]}

...

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1700000000,"model":"Qwen/Qwen3-0.6B","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":15,"total_tokens":25,"total_cost":2500}}

data: [DONE]
```

**Chunk Object:**

| Field | Description |
|-------|-------------|
| `delta.role` | Present only in first chunk |
| `delta.content` | Token(s) generated in this chunk |
| `finish_reason` | `null` until generation ends |
| `usage` | Present only in final chunk (before `[DONE]`) |

---

## Usage and Costs

Every response includes a `usage` object with token counts and costs.

**Usage Object:**

| Field | Type | Description |
|-------|------|-------------|
| `prompt_tokens` | integer | Number of input tokens |
| `completion_tokens` | integer | Number of generated tokens |
| `total_tokens` | integer | Sum of prompt + completion |
| `cached_tokens` | integer | Tokens served from KV cache (when applicable) |
| `reasoning_tokens` | integer | Internal reasoning tokens (o1-style models) |
| `prompt_total_cost` | integer | Cost of prompt tokens in nanoTON |
| `completion_total_cost` | integer | Cost of completion tokens in nanoTON |
| `total_cost` | integer | Total cost in nanoTON |

**Cost Calculation:**

```
prompt_cost = prompt_tokens × price_per_token × prompt_multiplier × coefficient
completion_cost = completion_tokens × price_per_token × completion_multiplier × coefficient
total_cost = prompt_cost + completion_cost
```

Where:
- `price_per_token` — base price set in root contract
- `prompt_multiplier`, `completion_multiplier` — token type multipliers
- `coefficient` — worker's price coefficient

**Converting nanoTON to TON:**

```
TON = nanoTON / 1,000,000,000
```

Example: `total_cost: 2500` = 0.0000025 TON

---

## Status and Monitoring Endpoints

### GET /stats

HTML dashboard with client status, wallet info, and connection details.

```bash
curl http://localhost:10000/stats
```

Returns HTML page for browser viewing.

---

### GET /jsonstats

JSON statistics for programmatic monitoring.

```bash
curl http://localhost:10000/jsonstats
```

**Response:**

```json
{
  "status": {
    "wallet_balance": 5000000000,
    "ton_last_synced_at": 1700000000,
    "enabled": true,
    "git_commit": "abc123"
  },
  "stats": {
    "queries": {
      "total": 1500,
      "last_minute": 25,
      "last_5_minutes": 100,
      "last_hour": 500
    },
    "success": {
      "total": 1480,
      "last_minute": 25
    },
    "failed": {
      "total": 20,
      "last_minute": 0
    },
    "tokens": {
      "prompt_total": 150000,
      "completion_total": 75000
    },
    "bytes_received": {
      "total": 5000000
    },
    "bytes_sent": {
      "total": 1000000
    }
  },
  "wallet": {
    "address": "EQBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "balance": 5000000000,
    "seqno": 42,
    "pending_transactions": 0
  },
  "localconf": {
    "root_address": "EQCns7bYSp0igFvS1wpb5wsZjCKCV19MD5AVzI4EyxsnU73k",
    "owner_address": "UQAe4yPiYOyEtlRHB_Wqs0zUz-hNKubKMuLhyUTE_FszPBVR",
    "check_proxy_hash": false
  },
  "proxy_connections": [
    {
      "address": "proxy1.cocoon.org:11001",
      "is_ready": true,
      "proxy_sc_address": "EQByyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
    }
  ],
  "proxies": [
    {
      "address": "EQByyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy",
      "balance": 4000000000,
      "stake": 1000000000,
      "tokens_used": 50000
    }
  ]
}
```

**Key Fields:**

| Field | Description |
|-------|-------------|
| `status.wallet_balance` | CocoonWallet balance in nanoTON |
| `status.enabled` | Whether client is operational |
| `wallet.address` | Your CocoonWallet address |
| `wallet.balance` | Current balance in nanoTON |
| `wallet.seqno` | Transaction sequence number |
| `wallet.pending_transactions` | Queued transactions |
| `proxy_connections` | Active proxy connections |
| `proxies[].balance` | Your balance with this proxy |
| `proxies[].tokens_used` | Tokens consumed via this proxy |

**Useful jq queries:**

```bash
# Get wallet balance in TON
curl -s http://localhost:10000/jsonstats | jq '.wallet.balance / 1e9'

# Get CocoonWallet address
curl -s http://localhost:10000/jsonstats | jq -r '.wallet.address'

# Check if connected to proxies
curl -s http://localhost:10000/jsonstats | jq '.proxy_connections | length'

# Get total queries
curl -s http://localhost:10000/jsonstats | jq '.stats.queries.total'

# Get success rate
curl -s http://localhost:10000/jsonstats | jq '(.stats.success.total / .stats.queries.total * 100 | floor) as $rate | "\($rate)%"'
```

---

## Payment Management Endpoints

### GET /request/topup

Add funds to a proxy contract.

```bash
curl "http://localhost:10000/request/topup?proxy=EQByyyyy..."
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `proxy` | yes | Proxy contract address |

---

### GET /request/charge

Force a payment to proxy (usually happens automatically).

```bash
curl "http://localhost:10000/request/charge?proxy=EQByyyyy..."
```

---

### GET /request/withdraw

Withdraw excess funds from a proxy contract.

```bash
curl "http://localhost:10000/request/withdraw?proxy=EQByyyyy..."
```

---

### GET /request/close

Close connection with a proxy and return remaining funds.

```bash
curl "http://localhost:10000/request/close?proxy=EQByyyyy..."
```

Remaining balance will be sent to your `owner_address`.

---

## Debugging

### GET /request/debuglogentry

Get debug information for a specific request.

```bash
curl "http://localhost:10000/request/debuglogentry?request_guid=my-request-123"
```

Only works for requests sent with `enable_debug: true` and `request_guid` set.

**Example request with debugging:**

```bash
curl -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-0.6B",
    "messages": [{"role": "user", "content": "Hello"}],
    "enable_debug": true,
    "request_guid": "debug-test-001"
  }'

# Later, retrieve debug info
curl "http://localhost:10000/request/debuglogentry?request_guid=debug-test-001"
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "message": "Error description",
    "type": "error_type",
    "code": "error_code"
  }
}
```

**HTTP Status Codes:**

| Code | Type | Description |
|------|------|-------------|
| 400 | `invalid_request_error` | Malformed request or missing required fields |
| 401 | `authentication_error` | Invalid or missing access_hash |
| 404 | `not_found_error` | Endpoint or resource not found |
| 500 | `server_error` | Internal server error |
| 502 | `server_error` | Proxy or worker not available |
| 504 | `timeout_error` | Request timed out |

**Common Errors:**

```json
// Missing model
{
  "error": {
    "message": "missing field 'model'",
    "type": "invalid_request_error"
  }
}

// No workers available
{
  "error": {
    "message": "no available workers for model Qwen/Qwen3-0.6B",
    "type": "server_error"
  }
}

// Insufficient balance
{
  "error": {
    "message": "insufficient balance",
    "type": "server_error"
  }
}

// Timeout
{
  "error": {
    "message": "request timeout after 120s",
    "type": "timeout_error"
  }
}
```

---

## Code Examples

### Python with requests

```python
import requests

def chat(messages, model="Qwen/Qwen3-0.6B"):
    response = requests.post(
        "http://localhost:10000/v1/chat/completions",
        json={
            "model": model,
            "messages": messages,
            "max_tokens": 500
        }
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]

# Usage
result = chat([
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "What is 2+2?"}
])
print(result)
```

### Python with OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:10000/v1",
    api_key="not-needed"  # or your access_hash
)

response = client.chat.completions.create(
    model="Qwen/Qwen3-0.6B",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"}
    ],
    max_tokens=100,
    temperature=0.7
)

print(response.choices[0].message.content)
print(f"Tokens used: {response.usage.total_tokens}")
```

### Python Streaming

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:10000/v1",
    api_key="not-needed"
)

stream = client.chat.completions.create(
    model="Qwen/Qwen3-0.6B",
    messages=[{"role": "user", "content": "Write a short poem about AI"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
print()
```

### JavaScript / Node.js

```javascript
async function chat(messages, model = "Qwen/Qwen3-0.6B") {
  const response = await fetch("http://localhost:10000/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model,
      messages,
      max_tokens: 500
    })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error.message);
  }

  const data = await response.json();
  return data.choices[0].message.content;
}

// Usage
const result = await chat([
  { role: "user", content: "What is the meaning of life?" }
]);
console.log(result);
```

### JavaScript Streaming

```javascript
async function streamChat(messages) {
  const response = await fetch("http://localhost:10000/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "Qwen/Qwen3-0.6B",
      messages,
      stream: true
    })
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    const lines = chunk.split('\n');

    for (const line of lines) {
      if (line.startsWith('data: ') && line !== 'data: [DONE]') {
        const data = JSON.parse(line.slice(6));
        const content = data.choices[0]?.delta?.content;
        if (content) process.stdout.write(content);
      }
    }
  }
  console.log();
}

await streamChat([{ role: "user", content: "Count to 10" }]);
```

### cURL Examples

```bash
# Simple chat
curl -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-0.6B","messages":[{"role":"user","content":"Hello"}]}'

# With all parameters
curl -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-0.6B",
    "messages": [
      {"role": "system", "content": "You are a pirate."},
      {"role": "user", "content": "Tell me about the sea"}
    ],
    "max_tokens": 200,
    "temperature": 0.8,
    "top_p": 0.95,
    "stop": ["\n\n"]
  }'

# Streaming
curl -N -X POST http://localhost:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-0.6B","messages":[{"role":"user","content":"Count to 5"}],"stream":true}'

# With authentication
curl -X POST "http://localhost:10000/v1/chat/completions?access_hash=your_token" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-0.6B","messages":[{"role":"user","content":"Hello"}]}'

# Check balance
curl -s http://localhost:10000/jsonstats | jq '.wallet.balance / 1e9'
```

---

## Rate Limits and Best Practices

1. **Monitor your balance** — requests fail when balance is too low
2. **Use streaming** for long outputs — better UX, same cost
3. **Set reasonable max_tokens** — you pay for tokens generated
4. **Use stop sequences** — prevent runaway generation
5. **Handle errors gracefully** — implement retry logic for 502/504
6. **Use request_guid** — helps with debugging and tracking

---

## Links

- [GitHub Repository](https://github.com/TelegramMessenger/cocoon)
- [Website](https://cocoon.org)
- [Docker Deployment](docker.md)
