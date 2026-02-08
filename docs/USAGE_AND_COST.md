# Usage And Cost API

## Gateway RPC endpoints used

- `sessions.usage`:
  - Source of truth for aggregated usage totals and `aggregates.byProvider`.
  - Used by `GET /api/usage`.
- `usage.status`:
  - Optional provider quota snapshot (used percent by provider windows).
  - Used by `GET /api/usage` when available on the Gateway.
  - If unsupported, `/api/usage` still returns usage totals/by-provider from `sessions.usage`.
- `usage.cost`:
  - Source of truth for cost totals + daily history.
  - Used by `GET /api/cost`.

## Studio API response shapes

### `GET /api/usage`

```json
{
  "ok": true,
  "usage": {
    "updatedAt": 1739011200000,
    "total": {
      "input": 0,
      "output": 0,
      "cacheRead": 0,
      "cacheWrite": 0,
      "total": 0,
      "cost": 0,
      "inputCost": 0,
      "outputCost": 0,
      "cacheReadCost": 0,
      "cacheWriteCost": 0,
      "missingCostEntries": 0,
      "percentUsed": 0
    },
    "byProvider": {
      "anthropic": {
        "provider": "anthropic",
        "input": 0,
        "output": 0,
        "cacheRead": 0,
        "cacheWrite": 0,
        "total": 0,
        "cost": 0,
        "inputCost": 0,
        "outputCost": 0,
        "cacheReadCost": 0,
        "cacheWriteCost": 0,
        "missingCostEntries": 0,
        "count": 0,
        "status": "ok"
      }
    }
  }
}
```

Unsupported Gateway shape:

```json
{
  "ok": false,
  "unavailable": true,
  "error": "Unavailable on this Gateway version"
}
```

### `GET /api/cost`

```json
{
  "ok": true,
  "cost": {
    "updatedAt": 1739011200000,
    "total": {
      "amount": 0,
      "inputCost": 0,
      "outputCost": 0,
      "cacheReadCost": 0,
      "cacheWriteCost": 0,
      "missingCostEntries": 0
    },
    "timeseries": [
      {
        "date": "2026-02-07",
        "amount": 0,
        "input": 0,
        "output": 0,
        "cacheRead": 0,
        "cacheWrite": 0,
        "inputCost": 0,
        "outputCost": 0,
        "cacheReadCost": 0,
        "cacheWriteCost": 0
      }
    ]
  }
}
```

Unsupported Gateway shape:

```json
{
  "ok": false,
  "unavailable": true,
  "error": "Unavailable on this Gateway version"
}
```

## Provider mapping logic

- File read: `~/.openclaw/openclaw.json`
- Source field: `auth.profiles` object keys only
- Mapping rule:
  - `<provider>:<profile>` -> `<provider>`
  - Example: `anthropic:default` -> `anthropic`
  - Example: `minimax:default` -> `minimax`
- Only configured provider IDs are exposed and included in `/api/usage.byProvider`.

## Security notes

- APIs never return auth profile contents, API keys, tokens, passwords, or refresh data.
- Provider detection only reads provider IDs from profile key names.
- Usage/cost routes return normalized, allowlisted fields only.
- Unsupported-method errors are normalized to:
  - `Unavailable on this Gateway version`

## Manual test commands

```bash
# Usage endpoint
curl -s http://localhost:3000/api/usage | jq

# Cost endpoint
curl -s http://localhost:3000/api/cost | jq

# Security checks (must print no output)
curl -s http://localhost:3000/api/usage | grep -iE '(token|secret|password|apiKey|refresh)'
curl -s http://localhost:3000/api/cost | grep -iE '(token|secret|password|apiKey|refresh)'
```

UI checks:

- Usage Meter widget reads `/api/usage` (no demo fallback).
- Provider usage panel in Usage modal reads `/api/usage.byProvider`.
- Cost Tracker widget reads `/api/cost` (no demo fallback).
- If Gateway does not support usage/cost methods, widgets show:
  - `Unavailable on this Gateway version`
