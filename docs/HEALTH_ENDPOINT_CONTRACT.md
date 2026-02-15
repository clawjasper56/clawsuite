# Health Endpoint Contract

ClawSuite exposes a machine-readable health endpoint at:

- `GET /api/healthz`

## Contract version

- `schemaVersion: "1.0.0"`

## Response schema (v1)

```json
{
  "schemaVersion": "1.0.0",
  "service": "clawsuite",
  "status": "ok | degraded",
  "timestamp": "ISO-8601 UTC",
  "checks": {
    "gateway": {
      "status": "ok | fail",
      "attempt": "initial | reconnect",
      "error": "string (only when fail)"
    }
  }
}
```

## Status semantics

- `200` with `status: "ok"` when gateway connectivity is confirmed.
- `503` with `status: "degraded"` when both initial check and reconnect fail.

## Compatibility

- `/api/ping` remains available for legacy callers, and points callers to `/api/healthz`.
