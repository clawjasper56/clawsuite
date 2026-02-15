/**
 * Generate a UUID v4 that works in all contexts:
 * - Node.js (SSR)
 * - Browser secure context (has crypto.randomUUID)
 * - Browser non-secure context (polyfill)
 */

let nodeRandomUUID: (() => string) | null = null

// Try to load Node.js crypto.randomUUID (server-side only)
if (typeof process !== 'undefined' && process.versions?.node) {
  try {
    // Dynamic import for Node.js environment
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    nodeRandomUUID = require('node:crypto').randomUUID
  } catch {
    // Not available, fall back to polyfill
  }
}

function polyfillUUID(): string {
  const bytes = new Uint8Array(16)
  if (typeof globalThis !== 'undefined' && globalThis.crypto?.getRandomValues) {
    globalThis.crypto.getRandomValues(bytes)
  } else {
    // Fallback for very old environments
    for (let i = 0; i < 16; i++) {
      bytes[i] = Math.floor(Math.random() * 256)
    }
  }
  // Set version (4) and variant bits
  bytes[6] = (bytes[6] & 0x0f) | 0x40
  bytes[8] = (bytes[8] & 0x3f) | 0x80
  const hex = [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('')
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
}

/**
 * Generate a UUID v4 string.
 * Works in Node.js (SSR), browser secure and non-secure contexts.
 */
export function uuid(): string {
  // Node.js environment
  if (nodeRandomUUID) {
    return nodeRandomUUID()
  }

  // Browser with native crypto.randomUUID
  if (typeof globalThis !== 'undefined' && globalThis.crypto?.randomUUID) {
    return globalThis.crypto.randomUUID()
  }

  // Fallback polyfill
  return polyfillUUID()
}

export default uuid
