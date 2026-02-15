import { createFileRoute } from '@tanstack/react-router'
import { json } from '@tanstack/react-start'
import { gatewayConnectCheck, gatewayReconnect } from '../../server/gateway'

const HEALTH_CONTRACT_VERSION = '1.0.0'

function nowIso() {
  return new Date().toISOString()
}

export const Route = createFileRoute('/api/healthz')({
  server: {
    handlers: {
      GET: async () => {
        const timestamp = nowIso()

        try {
          await gatewayConnectCheck()
          return json({
            schemaVersion: HEALTH_CONTRACT_VERSION,
            service: 'clawsuite',
            status: 'ok',
            timestamp,
            checks: { gateway: { status: 'ok', attempt: 'initial' } },
          })
        } catch {
          try {
            await gatewayReconnect()
            return json({
              schemaVersion: HEALTH_CONTRACT_VERSION,
              service: 'clawsuite',
              status: 'ok',
              timestamp,
              checks: { gateway: { status: 'ok', attempt: 'reconnect' } },
            })
          } catch (retryErr) {
            return json(
              {
                schemaVersion: HEALTH_CONTRACT_VERSION,
                service: 'clawsuite',
                status: 'degraded',
                timestamp,
                checks: {
                  gateway: {
                    status: 'fail',
                    attempt: 'reconnect',
                    error:
                      retryErr instanceof Error
                        ? retryErr.message
                        : String(retryErr),
                  },
                },
              },
              { status: 503 },
            )
          }
        }
      },
    },
  },
})
