import { CloudIcon } from '@hugeicons/core-free-icons'
import { useQuery } from '@tanstack/react-query'
import { DashboardGlassCard } from './dashboard-glass-card'
import type { WeatherSnapshot } from './dashboard-types'

type WttrDescription = {
  value?: string
}

type WttrNearestArea = {
  areaName?: Array<WttrDescription>
}

type WttrCurrentCondition = {
  temp_C?: string
  weatherDesc?: Array<WttrDescription>
}

type WttrForecastDay = {
  date?: string
  maxtempC?: string
  mintempC?: string
  hourly?: Array<{
    weatherDesc?: Array<WttrDescription>
  }>
}

type WttrPayload = {
  nearest_area?: Array<WttrNearestArea>
  current_condition?: Array<WttrCurrentCondition>
  weather?: Array<WttrForecastDay>
}

function toWeatherEmoji(condition: string): string {
  const normalized = condition.toLowerCase()
  if (normalized.includes('snow') || normalized.includes('blizzard')) return '❄️'
  if (
    normalized.includes('rain') ||
    normalized.includes('drizzle') ||
    normalized.includes('storm')
  ) {
    return '🌧️'
  }
  if (normalized.includes('cloud') || normalized.includes('overcast')) return '🌤️'
  return '☀️'
}

function toNumber(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string') {
    const parsed = Number(value)
    if (Number.isFinite(parsed)) return parsed
  }
  return 0
}

function formatWeekday(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return 'N/A'
  return new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(date)
}

async function fetchWeather(): Promise<WeatherSnapshot> {
  const response = await fetch('https://wttr.in/?format=j1')
  if (!response.ok) throw new Error('Weather unavailable')
  const payload = (await response.json()) as WttrPayload

  const current = payload.current_condition?.[0]
  const condition = current?.weatherDesc?.[0]?.value?.trim() ?? 'Unknown'
  const location =
    payload.nearest_area?.[0]?.areaName?.[0]?.value?.trim() ?? 'Unknown'
  const temperatureC = toNumber(current?.temp_C)

  const forecast = (payload.weather ?? []).slice(0, 3).map(function mapDay(day, index) {
    const dayCondition =
      day.hourly?.[0]?.weatherDesc?.[0]?.value?.trim() ?? condition
    const label = day.date ? formatWeekday(day.date) : `Day ${index + 1}`
    return {
      id: day.date ?? `${index}`,
      label,
      highC: toNumber(day.maxtempC),
      lowC: toNumber(day.mintempC),
      condition: dayCondition,
      emoji: toWeatherEmoji(dayCondition),
    }
  })

  return {
    location,
    temperatureC,
    condition,
    emoji: toWeatherEmoji(condition),
    forecast,
  }
}

export function WeatherWidget() {
  const weatherQuery = useQuery({
    queryKey: ['dashboard', 'weather'],
    queryFn: fetchWeather,
    staleTime: 10 * 60 * 1000,
    refetchInterval: 15 * 60 * 1000,
    retry: 1,
  })

  if (weatherQuery.isError) {
    return (
      <DashboardGlassCard
        title="Weather"
        description="Local weather snapshot and near-term forecast."
        icon={CloudIcon}
        className="h-full"
      >
        <div className="flex h-[130px] items-center justify-center rounded-xl border border-primary-200 bg-primary-100/50 text-sm text-primary-600 text-pretty">
          Weather unavailable
        </div>
      </DashboardGlassCard>
    )
  }

  if (!weatherQuery.data) {
    return (
      <DashboardGlassCard
        title="Weather"
        description="Local weather snapshot and near-term forecast."
        icon={CloudIcon}
        className="h-full"
      >
        <div className="flex h-[130px] items-center justify-center rounded-xl border border-primary-200 bg-primary-100/50 text-sm text-primary-600 text-pretty">
          Loading weather...
        </div>
      </DashboardGlassCard>
    )
  }

  const weather = weatherQuery.data

  return (
    <DashboardGlassCard
      title="Weather"
      description="Local weather snapshot and near-term forecast."
      icon={CloudIcon}
      className="h-full"
    >
      <div className="rounded-xl border border-primary-200 bg-primary-100/55 p-3">
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0">
            <p className="line-clamp-1 text-sm font-medium text-ink text-balance">
              {weather.location}
            </p>
            <p className="mt-0.5 line-clamp-1 text-xs text-primary-600 text-pretty">
              {weather.condition}
            </p>
          </div>
          <p className="shrink-0 text-lg font-medium text-ink tabular-nums">
            {weather.emoji} {weather.temperatureC}C
          </p>
        </div>
      </div>
      <div className="mt-2 grid grid-cols-3 gap-2">
        {weather.forecast.map(function mapDay(day) {
          return (
            <div
              key={day.id}
              className="rounded-lg border border-primary-200 bg-primary-100/45 px-2 py-2 text-center"
            >
              <p className="text-[11px] text-primary-600 tabular-nums">{day.label}</p>
              <p className="mt-1 text-sm text-ink" title={day.condition}>
                {day.emoji}
              </p>
              <p className="mt-1 text-[11px] text-primary-700 tabular-nums">
                {day.highC}C/{day.lowC}C
              </p>
            </div>
          )
        })}
      </div>
    </DashboardGlassCard>
  )
}
