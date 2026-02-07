import { Clock01Icon } from '@hugeicons/core-free-icons'
import { useEffect, useMemo, useState } from 'react'
import { DashboardGlassCard } from './dashboard-glass-card'

function formatClock(date: Date, formatter: Intl.DateTimeFormat): string {
  return formatter.format(date)
}

function formatFullDate(date: Date, formatter: Intl.DateTimeFormat): string {
  return formatter.format(date)
}

export function TimeDateWidget() {
  const [now, setNow] = useState(function initializeNow() {
    return new Date()
  })

  const timezone = useMemo(function resolveTimezone() {
    return Intl.DateTimeFormat().resolvedOptions().timeZone ?? 'UTC'
  }, [])

  const clockFormatter = useMemo(function createClockFormatter() {
    return new Intl.DateTimeFormat(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    })
  }, [])

  const dateFormatter = useMemo(function createDateFormatter() {
    return new Intl.DateTimeFormat(undefined, {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    })
  }, [])

  useEffect(function setupClockInterval() {
    const intervalId = window.setInterval(function tick() {
      setNow(new Date())
    }, 1000)

    return function cleanupClockInterval() {
      window.clearInterval(intervalId)
    }
  }, [])

  return (
    <DashboardGlassCard
      title="Time & Date"
      description="Live local clock and calendar date."
      icon={Clock01Icon}
      className="h-full"
    >
      <div className="rounded-xl border border-primary-200 bg-primary-100/55 p-4">
        <p className="text-xs text-primary-600 tabular-nums text-pretty">{timezone}</p>
        <p className="mt-2 text-4xl font-medium font-mono text-ink tabular-nums">
          {formatClock(now, clockFormatter)}
        </p>
        <p className="mt-2 text-sm font-medium text-primary-700 text-pretty">
          {formatFullDate(now, dateFormatter)}
        </p>
      </div>
    </DashboardGlassCard>
  )
}
