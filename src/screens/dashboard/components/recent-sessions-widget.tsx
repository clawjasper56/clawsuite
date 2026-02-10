import { Clock01Icon, ArrowRight01Icon } from '@hugeicons/core-free-icons'
import { HugeiconsIcon } from '@hugeicons/react'
import { DashboardGlassCard } from './dashboard-glass-card'
import type { RecentSession } from './dashboard-types'
import { Button } from '@/components/ui/button'

type RecentSessionsWidgetProps = {
  sessions: Array<RecentSession>
  onOpenSession: (sessionKey: string) => void
  draggable?: boolean
  onRemove?: () => void
}

function formatSessionTimestamp(value: number): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return 'Unknown'

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date)
}

export function RecentSessionsWidget({
  sessions,
  onOpenSession,
  draggable = false,
  onRemove,
}: RecentSessionsWidgetProps) {
  return (
    <DashboardGlassCard
      title="Recent Sessions"
      description=""
      icon={Clock01Icon}
      draggable={draggable}
      onRemove={onRemove}
      className="h-full"
    >
      <div className="space-y-2">
        {sessions.map(function mapSession(session) {
          return (
            <Button
              key={session.friendlyId}
              variant="outline"
              className="group h-auto w-full flex-col items-start rounded-xl border-primary-200 bg-primary-50/80 px-3 py-2.5 transition-colors hover:bg-primary-100/70"
              onClick={function onSessionClick() {
                onOpenSession(session.friendlyId)
              }}
            >
              <div className="flex w-full items-center justify-between gap-3">
                <span className="line-clamp-1 text-sm font-medium text-ink text-balance">
                  {session.title}
                </span>
                <span className="flex shrink-0 items-center gap-1">
                  <span className="text-[11px] text-primary-600 tabular-nums">
                    {formatSessionTimestamp(session.updatedAt)}
                  </span>
                  <HugeiconsIcon icon={ArrowRight01Icon} size={12} strokeWidth={1.5} className="text-primary-300 opacity-0 transition-opacity group-hover:opacity-100" />
                </span>
              </div>
              <p className="mt-1 line-clamp-2 w-full text-left text-xs text-primary-600 text-pretty">
                {session.preview}
              </p>
            </Button>
          )
        })}
      </div>
    </DashboardGlassCard>
  )
}
