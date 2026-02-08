/**
 * Diagnostics bundle API endpoint
 * Phase 2.4-001: Export diagnostics bundle (safe)
 */
import { createAPIFileRoute } from '@tanstack/start/api'
import { getWebFn } from '@tanstack/start'
import { getGateway, isGatewayConnected } from '@/server/gateway'
import {
  redactObject,
  extractFolderName,
  DIAGNOSTICS_BUNDLE_VERSION,
  type DiagnosticsBundle,
} from '@/lib/diagnostics'

const MAX_EVENTS = 50
const MAX_DEBUG_ENTRIES = 20

async function fetchGatewayStatus(): Promise<{
  status: 'connected' | 'disconnected' | 'unknown'
  url: string
  uptime: string | null
}> {
  try {
    const gateway = getGateway()
    const connected = isGatewayConnected()

    if (!gateway) {
      return {
        status: 'unknown',
        url: 'Not configured',
        uptime: null,
      }
    }

    // Get connection info without revealing tokens
    const url = gateway.baseUrl || 'Not available'
    // Redact any tokens that might be in URL
    const safeUrl = url.replace(/[?&]token=[^&]+/gi, '?token=[REDACTED]')

    return {
      status: connected ? 'connected' : 'disconnected',
      url: safeUrl,
      uptime: null, // Would need to track this separately
    }
  } catch {
    return {
      status: 'unknown',
      url: 'Error fetching',
      uptime: null,
    }
  }
}

async function fetchProviders(): Promise<
  Array<{
    name: string
    status: 'active' | 'configured' | 'inactive'
    modelCount: number
  }>
> {
  try {
    const gateway = getGateway()
    if (!gateway || !isGatewayConnected()) return []

    const response = await gateway.call('config.providers', {})
    const providers = response?.providers || []

    return providers.map((p: Record<string, unknown>) => ({
      name: String(p.id || p.name || 'Unknown'),
      status: p.enabled ? 'active' : 'configured',
      modelCount: Array.isArray(p.models) ? p.models.length : 0,
    }))
  } catch {
    return []
  }
}

async function fetchRecentEvents(): Promise<
  Array<{
    timestamp: string
    level: string
    title: string
    source: string
  }>
> {
  // Activity events would come from the SSE stream
  // For now, return empty - the client will add from its buffer
  return []
}

export const APIRoute = createAPIFileRoute('/api/diagnostics')({
  GET: getWebFn(async ({ request }) => {
    const [gatewayInfo, providers] = await Promise.all([
      fetchGatewayStatus(),
      fetchProviders(),
    ])

    // Build the diagnostics bundle
    const bundle: DiagnosticsBundle = {
      version: DIAGNOSTICS_BUNDLE_VERSION,
      generatedAt: new Date().toISOString(),
      environment: {
        appVersion: process.env.npm_package_version || '2.0.0',
        os: `${process.platform} ${process.arch}`,
        nodeVersion: process.version,
        userAgent: request.headers.get('user-agent') || 'Unknown',
      },
      gateway: gatewayInfo,
      workspace: {
        folderName: extractFolderName(process.cwd()),
      },
      providers: providers.slice(0, 10), // Limit provider count
      recentEvents: [], // Client will populate from its buffer
      debugEntries: [], // Client will populate from its buffer
    }

    // Final redaction pass
    const redactedBundle = redactObject(bundle)

    return new Response(JSON.stringify(redactedBundle), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  }),
})
