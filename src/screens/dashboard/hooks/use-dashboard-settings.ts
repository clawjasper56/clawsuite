import { useCallback, useEffect, useState } from 'react'

export type DashboardSettings = {
  /** ZIP code, city name, or empty for auto-detect via timezone */
  weatherLocation: string
  /** 12 or 24 hour clock */
  clockFormat: '12h' | '24h'
}

const STORAGE_KEY = 'openclaw-dashboard-settings'

const DEFAULT_SETTINGS: DashboardSettings = {
  weatherLocation: '',
  clockFormat: '12h',
}

function readPersisted(): DashboardSettings {
  if (typeof window === 'undefined') return DEFAULT_SETTINGS

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY)
    if (!raw) return DEFAULT_SETTINGS
    const parsed = JSON.parse(raw) as Partial<DashboardSettings>
    return { ...DEFAULT_SETTINGS, ...parsed }
  } catch {
    return DEFAULT_SETTINGS
  }
}

function writePersisted(settings: DashboardSettings) {
  if (typeof window === 'undefined') return
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(settings))
  } catch {
    // ignore storage errors
  }
}

export function useDashboardSettings() {
  const [settings, setSettings] = useState<DashboardSettings>(DEFAULT_SETTINGS)

  useEffect(() => {
    setSettings(readPersisted())
  }, [])

  const update = useCallback(function updateSettings(
    patch: Partial<DashboardSettings>,
  ) {
    setSettings((prev) => {
      const next = { ...prev, ...patch }
      writePersisted(next)
      return next
    })
  }, [])

  return { settings, update }
}
