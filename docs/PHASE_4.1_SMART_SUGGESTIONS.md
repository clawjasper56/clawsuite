# Phase 4.1 — Smart Model Suggestions (Updated)

**Priority:** P0 Differentiation  
**Branch:** phase4.1-smart-suggestions  
**Base:** v2.0.6

## Goal

Proactively suggest better model choices to the user **without** auto-switching.

## Constraints

- **Opt-in only** — Default OFF, requires Settings toggle
- **Dynamic model detection** — No hardcoded model names
- **Per-session + global cooldowns** — Respect user dismissals
- **Reuse existing APIs** — `/api/models`, `/api/model-switch`
- **No new backend routes**

## Settings Toggle

**Location:** Settings → Smart Suggestions  
**Default:** OFF  
**Label:** "Enable Smart Model Suggestions"  
**Description:** "Get proactive suggestions to optimize cost and quality"

When disabled:
- No suggestions shown
- No localStorage writes
- No analytics

## Model Selection Logic

### Dynamic Model Discovery

Query `/api/models` to get configured models, then rank by:

1. **Cost metadata** (if available in response)
2. **Provider-specific priority** (fallback if no cost data)

### Provider Priority Lists (Fallback)

```typescript
const MODEL_TIERS = {
  anthropic: {
    budget: ['claude-3-5-haiku', 'claude-haiku'],
    balanced: ['claude-3-5-sonnet', 'claude-sonnet-4-5'],
    premium: ['claude-opus-4', 'claude-opus-4-5', 'claude-opus-4-6'],
  },
  openai: {
    budget: ['gpt-4o-mini'],
    balanced: ['gpt-4o', 'gpt-5.2-codex'],
    premium: ['o1', 'o1-preview'],
  },
  google: {
    budget: ['gemini-2.5-flash', 'gemini-1.5-flash'],
    balanced: ['gemini-2.5-pro', 'gemini-1.5-pro'],
    premium: ['gemini-2.0-flash-thinking'],
  },
}
```

### Suggestion Rules

**Suggest cheaper model when:**
- Current model is "balanced" or "premium" tier
- Last 3+ messages were simple (short, no code, no errors)
- Target: "budget" tier from same provider

**Suggest more powerful model when:**
- Current model is "budget" or "balanced" tier
- Recent message is complex (code, debugging, long queries)
- Target: next tier up (budget→balanced, balanced→premium)

### Cost Display

If cost metadata is available:
- "Switch to Gemini Flash → save ~90% per message"
- "Switch to Opus → better quality (2x cost)"

If cost metadata is missing:
- "Try a cheaper model?"
- "Try a more powerful model?"

## UX Design

### Toast Notification

```
┌────────────────────────────────────┐
│ 💡 Try Gemini Flash?               │
│ This chat seems lightweight.       │
│ Save ~90% per message.             │
│                                    │
│ [Switch] [Not for this session]   │
│ [Dismiss]                          │
└────────────────────────────────────┘
```

### Dismissal Options

1. **Dismiss** — Hide for 5 minutes (global cooldown)
2. **Not for this session** — Never suggest for this sessionKey
3. **Switch** — Apply suggestion immediately

## Cooldown Logic

### Global Cooldown
- Max 1 suggestion per 5 minutes (any session)
- Stored in `localStorage.modelSuggestionLastShown` (timestamp)

### Per-Session Cooldown
- Track sessionKey-specific dismissals
- Stored in `localStorage.modelSuggestionSessionDismissals` (JSON array)
- Format: `[{ sessionKey: 'main', timestamp: 1234567890 }]`
- Never suggest again for dismissed sessions

### Storage Schema

```typescript
{
  // Global cooldown
  "modelSuggestionLastShown": 1234567890,
  
  // Per-session dismissals
  "modelSuggestionSessionDismissals": [
    { sessionKey: "main", timestamp: 1234567890 },
    { sessionKey: "session-xyz", timestamp: 1234567890 }
  ]
}
```

## Implementation Plan

### New Components

1. **ModelSuggestionToast** (`src/components/model-suggestion-toast.tsx`)
   - Toast notification with suggestion text
   - Three buttons: Switch / Not for this session / Dismiss
   - Auto-dismiss after 15 seconds
   - Shows cost savings if available

2. **useModelSuggestions** (`src/hooks/use-model-suggestions.ts`)
   - Check if feature is enabled (from settings)
   - Analyze chat history for triggers
   - Query `/api/models` for available models
   - Rank models by tier (cost or priority)
   - Check cooldowns (global + per-session)
   - Emit suggestion events

### Data Sources (Existing)

- **Settings:** `useSettings()` hook (already exists)
- **Current model:** From session metadata (chat state)
- **Message history:** Already loaded in chat screen
- **Available models:** `/api/models`

### Suggestion Triggers (Client-Side Heuristics)

```typescript
// Simple task detection
function isSimpleTask(messages: Message[]): boolean {
  const recent = messages.slice(-3)
  return recent.every(m => 
    m.content.length < 200 &&
    !m.content.includes('```') &&
    !m.content.match(/debug|error|fix|refactor|architect/i)
  )
}

// Complex task detection
function isComplexTask(message: Message): boolean {
  return (
    message.content.length > 500 ||
    message.content.includes('```') ||
    message.content.match(/architecture|design|debug|refactor|optimize|plan/i)
  )
}

// Model tier detection
function getModelTier(modelId: string): 'budget' | 'balanced' | 'premium' {
  // Check provider-specific tiers
  for (const [provider, tiers] of Object.entries(MODEL_TIERS)) {
    if (tiers.budget.some(m => modelId.includes(m))) return 'budget'
    if (tiers.balanced.some(m => modelId.includes(m))) return 'balanced'
    if (tiers.premium.some(m => modelId.includes(m))) return 'premium'
  }
  return 'balanced' // default
}
```

## Files to Change

- `src/components/model-suggestion-toast.tsx` — NEW
- `src/hooks/use-model-suggestions.ts` — NEW
- `src/screens/chat/chat-screen.tsx` — Add hook + toast rendering
- `src/screens/settings/index.tsx` — Add toggle (if not already present)
- `src/stores/settings-store.ts` — Add `smartSuggestions` field (if not present)
- `docs/QA/phase4.1-smart-suggestions_TESTPLAN.md` — Test steps
- `docs/QA/phase4.1-smart-suggestions_RESULTS.md` — Test results

## Manual Test Plan

### T1: Feature Disabled (Default)
1. Open Settings
2. Verify "Enable Smart Model Suggestions" is OFF
3. Send messages
4. **Expected:** No suggestions appear

### T2: Enable Feature + Suggest Cheaper Model
1. Enable Smart Suggestions in Settings
2. Start on Sonnet
3. Send 3 short, simple messages
4. **Expected:** Toast suggests cheaper model (e.g., Haiku or Flash)

### T3: Suggest More Powerful Model
1. Enable Smart Suggestions
2. Start on Haiku or Flash
3. Send a complex code request
4. **Expected:** Toast suggests more powerful model (e.g., Sonnet or Opus)

### T4: Dismiss for Session
1. Get a suggestion
2. Click "Not for this session"
3. Send similar messages
4. **Expected:** No more suggestions for this session

### T5: Global Cooldown
1. Dismiss a suggestion
2. Open a different session
3. Trigger a suggestion within 5 minutes
4. **Expected:** No suggestion (global cooldown active)

### T6: Switch Model via Suggestion
1. Get a suggestion
2. Click "Switch to [Model]"
3. **Expected:** Model switches, toast confirms, chat continues

### T7: Cost Display
1. Trigger a suggestion (if cost metadata available)
2. **Expected:** "Save ~X%" or "2x cost" shown

## Security

- No secrets exposed in suggestions
- Model switching uses existing `/api/model-switch` (already sanitized)
- LocalStorage contains no sensitive data (only timestamps + sessionKeys)
- Feature is opt-in (no surprise data writes)

## Risks

- **Low:** Heuristics may be imperfect (can refine based on feedback)
- **UX:** Toasts might be annoying if too frequent (mitigated by cooldowns)
- **None:** No breaking changes, no new backend

## Deferred

- Server-side ML for smarter suggestions (future enhancement)
- Historical accuracy tracking (future analytics)
- Per-user preference learning (future personalization)
- Cost metadata in `/api/models` response (backend enhancement)

## Success Metrics (Future)

- % of suggestions accepted
- Cost savings from downshifts
- Quality improvements from upshifts
- Feature adoption rate
