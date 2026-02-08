# Phase 4.1 — Smart Model Suggestions Test Plan

## Prerequisites
- App running on localhost
- Gateway connected
- Multiple models configured (Anthropic, OpenAI, or Google)

## Test Cases

### T1: Feature Disabled by Default
1. Open Settings
2. Navigate to "Smart Suggestions" section
3. **Expected:** Toggle is OFF
4. Open a chat session
5. Send multiple messages
6. **Expected:** No suggestion toasts appear

### T2: Enable Feature
1. Open Settings
2. Enable "Smart Suggestions" toggle
3. **Expected:** Setting saved to localStorage
4. Navigate to chat
5. **Expected:** Feature is active

### T3: Suggest Cheaper Model (Simple Tasks)
1. Ensure Smart Suggestions enabled
2. Start a chat on Sonnet or Opus model
3. Send 3 short, simple messages:
   - "What's 2+2?"
   - "How are you?"
   - "Tell me a joke"
4. **Expected:** Toast appears suggesting cheaper model (e.g., Haiku, Flash)
5. **Expected:** Toast shows reason: "This chat seems lightweight"
6. **Expected:** Toast shows cost impact: "Save ~80% per message"

### T4: Suggest More Powerful Model (Complex Tasks)
1. Ensure Smart Suggestions enabled
2. Start a chat on Haiku or Flash model
3. Send a complex message with code:
   ```
   Write a React component that fetches data from an API and handles errors gracefully
   ```
4. **Expected:** Toast appears suggesting better model (e.g., Sonnet, Opus)
5. **Expected:** Toast shows reason: "This looks complex"
6. **Expected:** Toast shows cost impact if available

### T5: Dismiss Toast
1. Get a suggestion toast
2. Click the X (dismiss) button
3. **Expected:** Toast disappears
4. Send similar message within 5 minutes
5. **Expected:** No new toast (global cooldown active)

### T6: Dismiss for Session
1. Get a suggestion toast
2. Click "Not for this session" button
3. **Expected:** Toast disappears
4. Send similar messages in same session
5. **Expected:** No suggestions appear for this session
6. Open a different session
7. Trigger a suggestion
8. **Expected:** Toast appears (only dismissed for previous session)

### T7: Switch Model via Toast
1. Get a suggestion toast (e.g., "Try Gemini Flash")
2. Click "Switch" button
3. **Expected:** 
   - Model switches to suggested model
   - Toast disappears
   - Subsequent messages use new model

### T8: Global Cooldown
1. Dismiss a suggestion
2. Open a different session immediately
3. Trigger a new suggestion
4. **Expected:** No toast (5-minute global cooldown active)
5. Wait 5+ minutes
6. Trigger a suggestion
7. **Expected:** Toast appears

### T9: Auto-Dismiss
1. Get a suggestion toast
2. Do not interact with it
3. **Expected:** Toast auto-dismisses after 15 seconds

### T10: Multiple Models Available
1. Ensure multiple models configured (e.g., Claude + Gemini)
2. Trigger suggestions with different starting models
3. **Expected:** Suggestions use same-provider models when possible
4. **Expected:** Model names formatted correctly (e.g., "Gemini 2.5 Flash")

### T11: Feature Toggle Persistence
1. Enable Smart Suggestions
2. Refresh browser
3. **Expected:** Setting persists (still enabled)
4. Disable Smart Suggestions
5. Refresh browser
6. **Expected:** Setting persists (still disabled)

### T12: No Models Available
1. Start with no configured models
2. Enable Smart Suggestions
3. Send messages
4. **Expected:** No suggestions (graceful degradation)

## Edge Cases

### E1: Empty Message History
1. Enable Smart Suggestions
2. Start a new chat (0-2 messages)
3. **Expected:** No suggestions (not enough data)

### E2: Mixed Task Complexity
1. Send 2 simple messages + 1 complex
2. **Expected:** No downgrade suggestion (mixed signals)

### E3: Current Model Unknown
1. Suggestion logic uses default model
2. **Expected:** Suggestions still work with fallback

## Visual Checks

- Toast appears in bottom-right corner
- Toast has proper spacing and borders
- Icons render correctly
- Buttons are accessible and styled
- Text is readable and not truncated
- Settings toggle is properly styled
