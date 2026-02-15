# ClawSuite Health Contract Specification

**Version:** 2026-02-15
**Status:** Active
**Author:** ClawSuite Operations

---

## Overview

This document defines the machine-readable JSON health contract for ClawSuite services. All health endpoints MUST conform to this specification for compatibility with monitoring systems, orchestration platforms, and operational tooling.

---

## Endpoints

### `GET /health`

Full health status with all checks.

**Response:** `200 OK` (even if unhealthy - check `status.healthy` field)

```json
{
  "contract_version": "2026-02-15",
  "timestamp": "2026-02-15T19:57:00Z",
  "service": {
    "name": "clawsuite",
    "version": "1.2.3",
    "mode": "preview"
  },
  "status": {
    "healthy": true,
    "port_status": "listening",
    "http_status": "healthy",
    "pid": 12345
  },
  "checks": {
    "port": {
      "status": "listening",
      "target": "localhost:4173"
    },
    "http": {
      "status": "healthy",
      "target": "http://localhost:4173/"
    }
  },
  "error": null
}
```

### `GET /health/ready`

Readiness probe for Kubernetes/container orchestration.

**Responses:**
- `200 OK` with `{"ready": true}` - Service is ready to accept traffic
- `503 Service Unavailable` with `{"ready": false}` - Service not ready

```json
// 200 OK
{"ready": true}

// 503 Service Unavailable
{"ready": false}
```

### `GET /health/live`

Liveness probe for Kubernetes/container orchestration.

**Response:** `200 OK`

```json
{"alive": true}
```

If this endpoint doesn't respond, the container should be restarted.

### `GET /health/version`

Version information for debugging and compatibility checks.

**Response:** `200 OK`

```json
{
  "contract_version": "2026-02-15",
  "endpoint_version": "1.0.0",
  "service": {
    "name": "clawsuite",
    "version": "1.2.3"
  }
}
```

---

## Schema Definition

### Full Health Response

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ClawSuiteHealthResponse",
  "type": "object",
  "required": ["contract_version", "timestamp", "service", "status", "checks"],
  "properties": {
    "contract_version": {
      "type": "string",
      "format": "date",
      "description": "Contract version date (YYYY-MM-DD)"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 UTC timestamp of health check"
    },
    "service": {
      "type": "object",
      "required": ["name", "version"],
      "properties": {
        "name": {
          "type": "string",
          "const": "clawsuite"
        },
        "version": {
          "type": "string",
          "description": "Semantic version of the service"
        },
        "mode": {
          "type": "string",
          "enum": ["dev", "preview", "production"],
          "description": "Running mode"
        }
      }
    },
    "status": {
      "type": "object",
      "required": ["healthy", "port_status", "http_status"],
      "properties": {
        "healthy": {
          "type": "boolean",
          "description": "Overall health status"
        },
        "port_status": {
          "type": "string",
          "enum": ["listening", "not_listening", "unknown"],
          "description": "TCP port status"
        },
        "http_status": {
          "type": "string",
          "enum": ["healthy", "unhealthy", "unknown"],
          "description": "HTTP health status"
        },
        "pid": {
          "type": ["integer", "null"],
          "description": "Process ID if running"
        }
      }
    },
    "checks": {
      "type": "object",
      "description": "Individual health checks",
      "additionalProperties": {
        "type": "object",
        "required": ["status"],
        "properties": {
          "status": {
            "type": "string",
            "description": "Check-specific status"
          },
          "target": {
            "type": "string",
            "description": "What was checked"
          },
          "latency_ms": {
            "type": "number",
            "description": "Check latency in milliseconds"
          }
        }
      }
    },
    "error": {
      "type": ["string", "null"],
      "description": "Error message if unhealthy, null otherwise"
    }
  }
}
```

---

## Status Values

### `status.healthy`

| Value | Meaning |
|-------|---------|
| `true` | All checks passed, service is operational |
| `false` | One or more checks failed, service is degraded |

### `status.port_status`

| Value | Meaning |
|-------|---------|
| `listening` | TCP socket is bound and accepting connections |
| `not_listening` | TCP socket is not bound |
| `unknown` | Unable to determine port status |

### `status.http_status`

| Value | Meaning |
|-------|---------|
| `healthy` | HTTP request returned 2xx or 3xx |
| `unhealthy` | HTTP request failed or returned 4xx/5xx |
| `unknown` | Unable to perform HTTP check |

---

## Contract Versioning

Contract versions use date format `YYYY-MM-DD` for clarity.

**Version History:**

| Version | Date | Changes |
|---------|------|---------|
| 2026-02-15 | 2026-02-15 | Initial contract definition |

**Compatibility Rules:**
- Adding optional fields: Minor change, compatible
- Adding required fields: Major change, incompatible
- Removing fields: Major change, incompatible
- Changing field types: Major change, incompatible

---

## Implementation

### Shell Script

```bash
./scripts/ops/health-endpoint.sh --port 4180 --daemonize
curl http://localhost:4180/health
```

### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 4180
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 4180
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

### Docker Compose

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:4180/health/ready"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 10s
```

---

## Verification Commands

### Manual Health Check

```bash
# Full health
curl -s http://localhost:4180/health | jq .

# Check if healthy (exit 0 = healthy)
curl -sf http://localhost:4180/health/ready && echo "HEALTHY" || echo "UNHEALTHY"

# Liveness
curl -sf http://localhost:4180/health/live && echo "ALIVE"

# Version
curl -s http://localhost:4180/health/version | jq .
```

### Contract Validation

```bash
# Validate JSON structure
curl -s http://localhost:4180/health | jq -e '.contract_version, .timestamp, .service.name, .status.healthy'

# Validate contract version matches
curl -s http://localhost:4180/health | jq -r '.contract_version' | grep -q "2026-02-15" && echo "Contract valid"
```

---

## Error Handling

### Unhealthy Response Example

```json
{
  "contract_version": "2026-02-15",
  "timestamp": "2026-02-15T19:57:00Z",
  "service": {
    "name": "clawsuite",
    "version": "1.2.3",
    "mode": "preview"
  },
  "status": {
    "healthy": false,
    "port_status": "not_listening",
    "http_status": "unhealthy",
    "pid": null
  },
  "checks": {
    "port": {
      "status": "not_listening",
      "target": "localhost:4173"
    },
    "http": {
      "status": "unhealthy",
      "target": "http://localhost:4173/"
    }
  },
  "error": "Port 4173 is not listening"
}
```

---

## Monitoring Integration

### Prometheus Metrics (Future)

```
# HELP clawsuite_health_status Overall health status (1=healthy, 0=unhealthy)
# TYPE clawsuite_health_status gauge
clawsuite_health_status 1

# HELP clawsuite_port_status Port listening status (1=listening, 0=not)
# TYPE clawsuite_port_status gauge
clawsuite_port_status 1

# HELP clawsuite_http_status HTTP health status (1=healthy, 0=unhealthy)
# TYPE clawsuite_http_status gauge
clawsuite_http_status 1
```

---

**Last Updated:** 2026-02-15
**Maintainer:** ClawSuite Operations
