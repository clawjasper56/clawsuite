/**
 * Compact ambient time + weather readout for the dashboard header.
 * Reuses the same weather query and dashboard settings as the grid widgets.
 * Example: "04:12 PM · Feb 10 · 🌤 62°"
 */
import { useQuery } from '@tanstack/react-query'
import { useEffect, useMemo, useState } from 'react'
import { useDashboardSettings } from '../hooks/use-dashboard-settings'

type WttrCurrentCondition = {
  temp_C?: string
  weatherDesc?: Array<{ value?: string }>
}

type WttrPayload = {
  current_condition?: Array<WttrCurrentCondition>
}

function toWeatherEmoji(condition: string): string {
  const n = condition.toLowerCase()
  if (n.includes('snow') || n.includes('blizzard')) return '❄️'
  if (n.includes('rain') || n.includes('drizzle') || n.includes('storm')) return '🌧️'
  if (n.includes('cloud') || n.includes('overcast')) return '🌤️'
  return '☀️'
}

function cToF(c: number): number {
  return Math.round((c * 9) / 5 + 32)
}

function deriveLocationFromTimezone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone?.split('/').pop()?.replace(/_/g, ' ') ?? ''
  } catch {
    return ''
  }
}

async function fetchCompactWeather(location?: string): Promise<{ emoji: string; tempF: number } | null> {
  try {
    const loc = location?.trim() || deriveLocationFromTimezone()
    const url = loc
      ? `https://wttr.in/${encodeURIComponent(loc)}?format=j1`
      : 'https://wttr.in/?format=j1'
    const res = await fetch(url)
    if (!res.ok) return null
    const data = (await res.json()) as WttrPayload
    const cur = data.current_condition?.[0]
    const condition = cur?.weatherDesc?.[0]?.value?.trim() ?? 'Unknown'
    const tempC = Number(cur?.temp_C) || 0
    return { emoji: toWeatherEmoji(condition), tempF: cToF(tempC) }
  } catch {
    return null
  }
}

export function HeaderAmbientStatus() {
  const { settings } = useDashboardSettings()
  const is12h = settings.clockFormat === '12h'

  const [now, setNow] = useState(() => new Date())

  useEffect(() => {
    // Tick every 30s — minute-level precision is fine for header
    const id = setInterval(() => setNow(new Date()), 30_000)
    return () => clearInterval(id)
  }, [])

  const timeStr = useMemo(() => {
    return new Intl.DateTimeFormat(undefined, {
      hour: 'numeric',
      minute: '2-digit',
      hour12: is12h,
    }).format(now)
  }, [now, is12h])

  const dateStr = useMemo(() => {
    return new Intl.DateTimeFormat(undefined, {
      month: 'short',
      day: 'numeric',
    }).format(now)
  }, [now])

  const weatherQuery = useQuery({
    queryKey: ['dashboard', 'weather', settings.weatherLocation],
    queryFn: () => fetchCompactWeather(settings.weatherLocation),
    staleTime: 10 * 60 * 1000,
    refetchInterval: 15 * 60 * 1000,
    retry: 1,
  })

  const weather = weatherQuery.data

  return (
    <span className="hidden items-center gap-1.5 text-xs text-primary-500 tabular-nums sm:inline-flex">
      <span>{timeStr}</span>
      <span className="text-primary-300">·</span>
      <span>{dateStr}</span>
      {weather ? (
        <>
          <span className="text-primary-300">·</span>
          <span>{weather.emoji} {weather.tempF}°</span>
        </>
      ) : null}
    </span>
  )
}
