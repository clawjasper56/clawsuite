'use client'

import { useQuery } from '@tanstack/react-query'

async function pingGateway(): Promise<boolean> {
  try {
    const response = await fetch('/api/ping', {
      signal: AbortSignal.timeout(5000),
    })
    if (!response.ok) return false
    const data = (await response.json()) as { ok?: boolean }
    return Boolean(data.ok)
  } catch {
    return false
  }
}

export function GatewayStatusIndicator({ collapsed }: { collapsed?: boolean }) {
  const { data: isConnected, isLoading } = useQuery({
    queryKey: ['gateway', 'ping'],
    queryFn: pingGateway,
    refetchInterval: 15_000,
    retry: false,
  })

  const dotColor = isLoading
    ? 'bg-yellow-400'
    : isConnected
      ? 'bg-emerald-400'
      : 'bg-red-400'

  const pulseColor = isLoading
    ? 'bg-yellow-400/40'
    : isConnected
      ? 'bg-emerald-400/40'
      : 'bg-red-400/40'

  const label = isLoading
    ? 'Connecting...'
    : isConnected
      ? 'Gateway Connected'
      : 'Gateway Offline'

  return (
    <div className="flex items-center gap-2 px-2 py-1.5" title={label}>
      <span className="relative flex h-2 w-2 shrink-0">
        {(isLoading || isConnected) && (
          <span
            className={`absolute inline-flex h-full w-full animate-ping rounded-full ${pulseColor}`}
          />
        )}
        <span
          className={`relative inline-flex h-2 w-2 rounded-full ${dotColor}`}
        />
      </span>
      {!collapsed && (
        <span className="truncate text-[11px] text-primary-500">{label}</span>
      )}
    </div>
  )
}
