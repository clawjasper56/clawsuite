import { create } from 'zustand'

const SETUP_STORAGE_KEY = 'clawsuite-gateway-configured'

type GatewaySetupState = {
  isOpen: boolean
  step: 'gateway' | 'provider' | 'complete'
  connectionOk: boolean
  testStatus: 'idle' | 'testing' | 'success' | 'error'
  testError: string | null
  _initialized: boolean
  initialize: () => Promise<void>
  testConnection: () => Promise<boolean>
  proceed: () => void
  skipProviderSetup: () => void
  completeSetup: () => void
  reset: () => void
  open: () => void
}

/**
 * Test gateway connectivity through ClawSuite's server-side /api/ping.
 * The gateway is a WebSocket server — browsers can't connect directly.
 * /api/ping does the real WS handshake on the server and returns {ok: true/false}.
 */
async function pingGateway(): Promise<{ ok: boolean; error?: string }> {
  try {
    const response = await fetch('/api/ping', {
      signal: AbortSignal.timeout(8000),
    })
    const data = (await response.json()) as { ok?: boolean; error?: string }
    return { ok: Boolean(data.ok), error: data.error }
  } catch {
    return { ok: false, error: 'Could not reach ClawSuite server' }
  }
}

export const useGatewaySetupStore = create<GatewaySetupState>((set, get) => ({
  isOpen: false,
  step: 'gateway',
  connectionOk: false,
  testStatus: 'idle',
  testError: null,
  _initialized: false,

  initialize: async () => {
    if (get()._initialized) return
    set({ _initialized: true })
    if (typeof window === 'undefined') return

    try {
      // If already configured, just verify silently
      const configured = localStorage.getItem(SETUP_STORAGE_KEY) === 'true'

      const { ok } = await pingGateway()

      if (ok) {
        // Gateway works — mark configured, don't show wizard
        localStorage.setItem(SETUP_STORAGE_KEY, 'true')
        set({ connectionOk: true })
        return
      }

      if (configured) {
        // Was configured before but now unreachable — don't show full wizard,
        // the reconnect banner handles this
        set({ connectionOk: false })
        return
      }

      // First run + gateway not working → show wizard
      set({ isOpen: true, step: 'gateway', connectionOk: false })
    } catch {
      // Ignore init errors
    }
  },

  testConnection: async () => {
    set({ testStatus: 'testing', testError: null })

    const { ok, error } = await pingGateway()

    if (ok) {
      set({ testStatus: 'success', testError: null, connectionOk: true })
      return true
    }

    set({
      testStatus: 'error',
      testError: error || 'Gateway not reachable. Check your .env configuration.',
    })
    return false
  },

  proceed: () => {
    set({ step: 'provider' })
  },

  skipProviderSetup: () => {
    localStorage.setItem(SETUP_STORAGE_KEY, 'true')
    set({ isOpen: false, step: 'complete' })
  },

  completeSetup: () => {
    localStorage.setItem(SETUP_STORAGE_KEY, 'true')
    set({ isOpen: false, step: 'complete' })
  },

  reset: () => {
    localStorage.removeItem(SETUP_STORAGE_KEY)
    set({
      isOpen: true,
      step: 'gateway',
      connectionOk: false,
      testStatus: 'idle',
      testError: null,
    })
  },

  open: () => {
    set({ isOpen: true, step: 'gateway', testStatus: 'idle', testError: null })
  },
}))
