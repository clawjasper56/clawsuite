import { createFileRoute } from '@tanstack/react-router'
import { json } from '@tanstack/react-start'
import { gatewayRpc } from '../../server/gateway'

const SESSION_STATUS_METHODS = [
  'session.status',
  'sessions.status', 
  'session_status',
  'status',
]

async function trySessionStatus(): Promise<unknown> {
  let lastError: unknown = null
  for (const method of SESSION_STATUS_METHODS) {
    try {
      return await gatewayRpc(method)
    } catch (error) {
      lastError = error
    }
  }
  throw lastError instanceof Error ? lastError : new Error('Session status unavailable')
}

export const Route = createFileRoute('/api/session-status')({
  server: {
    handlers: {
      GET: async () => {
        try {
          const payload = await trySessionStatus()
          return json({ ok: true, payload })
        } catch (err) {
          return json(
            {
              ok: false,
              error: err instanceof Error ? err.message : String(err),
            },
            { status: 503 },
          )
        }
      },
    },
  },
})
