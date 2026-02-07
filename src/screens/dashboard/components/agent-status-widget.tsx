import { AiChat01Icon } from '@hugeicons/core-free-icons'
import { useQuery } from '@tanstack/react-query'
import { useMemo } from 'react'
import { DashboardGlassCard } from './dashboard-glass-card'
import type { AgentStatusSummary } from './dashboard-types'
import { cn } from '@/lib/utils'

type SessionStatusResponse = {
  ok?: boolean
  payload?: unknown
  error?: string
}

type SessionsApiResponse = {
  sessions?: Array<Record<string, unknown>>
}

function readString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : ''
}

function readNumber(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string') {
    const parsed = Number(value)
    if (Number.isFinite(parsed)) return parsed
  }
  return 0
}

async function fetchSessionStatus(): Promise<SessionStatusResponse> {
  const response = await fetch('/api/session-status')
  if (!response.ok) return { ok: false, error: 'Status unavailable' }
  return (await response.json()) as SessionStatusResponse
}

async function fetchSessions(): Promise<Array<Record<string, unknown>>> {
  const response = await fetch('/api/sessions')
  if (!response.ok) return []
  const payload = (await response.json()) as SessionsApiResponse
  return Array.isArray(payload.sessions) ? payload.sessions : []
}

function parseAgentStatus(
  statusPayload: SessionStatusResponse | undefined,
  sessions: Array<Record<string, unknown>>,
): AgentStatusSummary {
  const root =
    statusPayload && typeof statusPayload.payload === 'object'
      ? (statusPayload.payload as Record<string, unknown>)
      : {}
  const model =
    readString(root.model) ||
    readString(root.currentModel) ||
    readString(root.agentModel) ||
    readString(sessions[0]?.model) ||
    'unknown'
  const provider =
    readString(root.provider) ||
    readString(root.vendor) ||
    readString(root.apiProvider) ||
    readString(sessions[0]?.provider) ||
    'unknown'
  const activeSessionsFromStatus =
    readNumber(root.activeSessions) ||
    readNumber(root.sessionCount) ||
    readNumber(root.sessions)
  const activeSessions = activeSessionsFromStatus || sessions.length
  const statusText = readString(root.status).toLowerCase()
  const connected = statusPayload?.ok !== false && !statusText.includes('error')

  return {
    connected,
    model,
    provider,
    activeSessions,
  }
}

export function AgentStatusWidget() {
  const sessionStatusQuery = useQuery({
    queryKey: ['dashboard', 'session-status'],
    queryFn: fetchSessionStatus,
    refetchInterval: 15_000,
  })

  const sessionsQuery = useQuery({
    queryKey: ['dashboard', 'agent-sessions'],
    queryFn: fetchSessions,
    refetchInterval: 20_000,
  })

  const status = useMemo(function buildStatus() {
    const sessions = Array.isArray(sessionsQuery.data) ? sessionsQuery.data : []
    return parseAgentStatus(sessionStatusQuery.data, sessions)
  }, [sessionStatusQuery.data, sessionsQuery.data])

  return (
    <DashboardGlassCard
      title="Agent Status"
      description="Active model, provider, and live session count."
      icon={AiChat01Icon}
      className="h-full"
    >
      <div className="space-y-2">
        <div className="flex items-center justify-between rounded-xl border border-primary-200 bg-primary-100/50 px-3 py-2.5">
          <span className="text-primary-700 text-pretty">Status</span>
          <span className="inline-flex items-center gap-2 tabular-nums">
            <span
              className={cn(
                'size-2 rounded-full',
                status.connected ? 'bg-emerald-500' : 'bg-red-500',
              )}
              aria-hidden="true"
            />
            <span className="text-sm font-medium text-ink">
              {status.connected ? 'Online' : 'Offline'}
            </span>
          </span>
        </div>
        <div className="flex items-center justify-between rounded-xl border border-primary-200 bg-primary-100/50 px-3 py-2.5">
          <span className="text-primary-700 text-pretty">Model</span>
          <span className="line-clamp-1 text-sm font-medium text-ink tabular-nums">
            {status.model}
          </span>
        </div>
        <div className="flex items-center justify-between rounded-xl border border-primary-200 bg-primary-100/50 px-3 py-2.5">
          <span className="text-primary-700 text-pretty">Provider</span>
          <span className="line-clamp-1 text-sm font-medium text-ink tabular-nums">
            {status.provider}
          </span>
        </div>
        <div className="flex items-center justify-between rounded-xl border border-primary-200 bg-primary-100/50 px-3 py-2.5">
          <span className="text-primary-700 text-pretty">Active sessions</span>
          <span className="text-sm font-medium text-ink tabular-nums">
            {status.activeSessions}
          </span>
        </div>
      </div>
    </DashboardGlassCard>
  )
}
