import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'

type GatewayConfig = {
  auth?: {
    profiles?: Record<string, { provider?: string }>
  }
  models?: {
    providers?: Record<string, { models?: Array<{ id?: string }> }>
  }
}

let cachedProviderNames: Array<string> | null = null
let cachedModelIds: Set<string> | null = null

/**
 * Extract provider name from auth profile key.
 * Example: "anthropic:default" -> "anthropic"
 */
function providerNameFromProfileKey(profileKey: string): string | null {
  const raw = profileKey.split(':')[0]?.trim().toLowerCase() ?? ''
  if (raw.length === 0) return null
  return raw
}

/**
 * Read configured provider names from auth.profiles keys in ~/.openclaw/openclaw.json.
 * Returns only provider names (e.g., ["anthropic", "openrouter"]), never secrets.
 */
export function getConfiguredProviderNames(): Array<string> {
  if (cachedProviderNames) return cachedProviderNames

  const configPath = path.join(os.homedir(), '.openclaw', 'openclaw.json')

  try {
    const raw = fs.readFileSync(configPath, 'utf8')
    const config = JSON.parse(raw) as GatewayConfig

    const providerNames = new Set<string>()

    if (config.auth?.profiles) {
      for (const profileKey of Object.keys(config.auth.profiles)) {
        const providerName = providerNameFromProfileKey(profileKey)
        if (providerName) providerNames.add(providerName)
      }
    }

    cachedProviderNames = Array.from(providerNames).sort()
    return cachedProviderNames
  } catch (error) {
    console.error('Failed to read Gateway config for provider names:', error)
    return []
  }
}

/**
 * Backward-compatible alias.
 */
export function getConfiguredProviders(): Array<string> {
  return getConfiguredProviderNames()
}

/**
 * Read configured model IDs from the Gateway config file.
 * Returns a Set of allowed model IDs (e.g., {"claude-opus-4-6", "gpt-5-codex"}).
 */
export function getConfiguredModelIds(): Set<string> {
  if (cachedModelIds) return cachedModelIds

  const configPath = path.join(os.homedir(), '.openclaw', 'openclaw.json')

  try {
    const raw = fs.readFileSync(configPath, 'utf8')
    const config = JSON.parse(raw) as GatewayConfig

    const modelIds = new Set<string>()

    if (config.models?.providers) {
      for (const providerConfig of Object.values(config.models.providers)) {
        if (providerConfig.models) {
          for (const model of providerConfig.models) {
            if (model.id) {
              modelIds.add(model.id)
            }
          }
        }
      }
    }

    cachedModelIds = modelIds
    return cachedModelIds
  } catch (error) {
    console.error('Failed to read Gateway config for model IDs:', error)
    return new Set()
  }
}
