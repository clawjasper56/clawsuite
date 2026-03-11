# Dashboard Actionable Insights Review

**Pass 2 Focus:** What decisions can users make from this data?  
**Review Date:** 2026-02-22  
**Analyst:** Researcher Subagent

---

## Executive Summary

The current ClawSuite dashboard presents data effectively but lacks **actionability** — most widgets show "what" without guiding users to "what next." Users must mentally compute implications and hunt for next steps themselves.

**Key Finding:** 6 of 7 widgets are **informational dead-ends** with no clear call-to-action. Only the Recent Sessions widget offers a natural next step (click to open session).

**Recommendation:** Transform the dashboard from a "status display" into an "action center" by adding:
1. System health indicators with clear states
2. Proactive alerts for problems
3. Suggested next actions based on current state
4. Contextual thresholds for all metrics

---

## Current State: What's Actionable?

### Hero Metrics Analysis

| Metric | Current Behavior | Actionability Score | Problem |
|--------|-----------------|---------------------|---------|
| **Total Sessions** | Shows count (e.g., "12") | ⭐☆☆☆☆ Low | Just a number. User asks: "Is 12 good? Bad? Normal?" No context, no trend, no action. |
| **Active Agents** | Shows count (e.g., "3") | ⭐⭐☆☆☆ Low | Slightly better — implies "something is happening." But user can't click, can't see which agents, can't take action. |
| **Uptime** | Shows time (e.g., "2d 5h") | ⭐☆☆☆☆ None | Pure FYI. Uptime of what? Main session? Gateway? User can't do anything with this. |
| **Cost** | Shows dollar amount (e.g., "$12.45") | ⭐⭐☆☆☆ Low | Better than others — users care about cost. But missing: budget context, trends, projections. Is $12 good? Expensive? |

**Verdict:** Hero metrics are "dashboard dressing" — nice to see but don't guide decisions.

**Fix:** Add trend arrows, budget context, and color-coded thresholds.

---

### Widget Actionability Analysis

#### 1. Tasks Widget
**What it shows:** Mini Kanban board with task counts by status (in_progress, review, done, backlog)

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | See which tasks exist, their status | ⭐⭐⭐☆☆ Medium |
| **Call-to-Action** | "View all" link to /cron page | ✅ Present |
| **Alerts Surfaced** | P0 priority badge (red) for failed tasks | ⚠️ Weak |

**What's Missing:**
- No "failed tasks" alert banner when tasks fail
- No indication of how long tasks have been stuck
- No "retry failed" or "view errors" quick action
- No proactive notification when P0 tasks appear

**Actionability Gap:** Widget shows task exists but doesn't say "HEY, THIS FAILED, FIX IT NOW"

---

#### 2. Agent Status Widget
**What it shows:** List of active sessions with name, model, and relative time

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | See which sessions are active | ⭐⭐⭐☆☆ Medium |
| **Call-to-Action** | None — no click-to-open | ❌ Missing |
| **Alerts Surfaced** | Status dot (running vs idle) | ⚠️ Minimal |

**What's Missing:**
- **No way to interact** — can't click to open session
- No "stuck agent" detection (running >30m with no output)
- No model cost indication
- No quick actions (pause, resume, kill)

**Actionability Gap:** Widget says "agents exist" but doesn't help user manage them

---

#### 3. Recent Sessions Widget
**What it shows:** Last 5 sessions with title, preview, timestamp. **Click to open.**

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | Resume recent conversations | ⭐⭐⭐⭐☆ High |
| **Call-to-Action** | Click row to navigate to session | ✅ Strong |
| **Alerts Surfaced** | None | ❌ Missing |

**What's Working:** This is the **most actionable widget**. Clear mental model: "Here's what I was doing, click to continue."

**What's Missing:**
- No "new session" button (user must use sidebar)
- No session health indicators (errors in session?)

---

#### 4. Activity Log Widget
**What it shows:** Real-time event stream from gateway with live/disconnected status

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | Monitor system activity | ⭐⭐☆☆☆ Low-Medium |
| **Call-to-Action** | "View all" link to /activity | ✅ Present |
| **Alerts Surfaced** | "Disconnected" banner with reconnect button | ⚠️ Basic |

**What's Working:**
- Live status indicator is good
- Reconnect button when disconnected is actionable

**What's Missing:**
- **Error events don't stand out** — should be highlighted/prominent
- No "investigate this error" quick action
- No filtering by severity
- Events scroll by without user control

**Actionability Gap:** Shows events but doesn't say "this error needs your attention"

---

#### 5. Usage Meter Widget
**What it shows:** Token usage, costs, provider quotas with visual progress bars

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | Track spending and quotas | ⭐⭐⭐☆☆ Medium |
| **Call-to-Action** | None | ❌ Missing |
| **Alerts Surfaced** | Progress bar color (yellow at 75%, red at 90%) | ⚠️ Weak |

**What's Working:**
- Visual progress bars for quotas
- Provider status indicators
- Cost breakdown by provider

**What's Missing:**
- **No budget threshold alerts** — user must notice red bar
- No "projected spend this month"
- No "you're on track / over budget" summary
- No cost optimization suggestions

**Actionability Gap:** Shows costs but doesn't help user control them

---

#### 6. Skills Widget
**What it shows:** Installed skills with enabled/disabled status

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | See what's installed | ⭐⭐☆☆☆ Low |
| **Call-to-Action** | "Open Skills" button | ✅ Present |
| **Alerts Surfaced** | None | ❌ Missing |

**What's Missing:**
- No indication of which skills are actually being used
- No "recommended skills" based on usage patterns
- No quick toggle for enable/disable
- No skill health/status

**Actionability Gap:** Just a list — doesn't help user manage or discover skills

---

#### 7. Notifications Widget
**What it shows:** Session lifecycle events (starts, errors, cron jobs)

| Aspect | Current State | Score |
|--------|---------------|-------|
| **Decision Enabled** | See what happened | ⭐⭐☆☆☆ Low |
| **Call-to-Action** | None | ❌ Missing |
| **Alerts Surfaced** | Error label in red | ⚠️ Minimal |

**What's Missing:**
- **Can't act on notifications** — no click-through
- No severity classification
- No "mark as read" or "dismiss"
- No filtering

**Actionability Gap:** Shows notifications but they're dead ends

---

## Dead-End Data (Remove or Contextualize)

### High-Priority Fixes

| Data | Why It's Dead-End | Fix |
|------|-------------------|-----|
| **Uptime metric** | Pure FYI, no decision value | Remove OR add context: "Gateway uptime: 2d 5h (last restart: Feb 20)" |
| **Total Sessions count** | Number without context | Add trend: "12 sessions (↑3 this week)" OR merge into Recent Sessions |
| **Skills list** | No interaction, no insights | Add "Most used skill this week" or remove if not valuable |

### Medium-Priority Fixes

| Data | Why It's Dead-End | Fix |
|------|-------------------|-----|
| **Activity Log events** | Scroll by passively | Add severity filter, star/highlight errors |
| **Notifications** | Can't act on them | Make clickable → navigate to relevant session |
| **Agent Status rows** | Can't open sessions | Add click handler to navigate |

---

## Alert & Threshold Recommendations

### Alert Severity Framework

| Level | Visual | When to Use | Example |
|-------|--------|-------------|---------|
| **Info** | 🔵 Blue dot/badge | FYI, no action needed | "Session started" |
| **Warning** | 🟡 Yellow/amber | Attention recommended, not urgent | "Cost at 75% of budget" |
| **Critical** | 🔴 Red + prominent | Immediate action required | "Gateway disconnected", "3 tasks failed" |

### Recommended Thresholds

#### Cost Alerts
```
Info:    < 50% of monthly budget
Warning: 50-80% of monthly budget (show projection)
Critical: > 80% of monthly budget OR projected to exceed
```

#### Usage Alerts
```
Info:    < 70% of provider quota
Warning: 70-90% of provider quota
Critical: > 90% of provider quota OR rate-limited
```

#### Task Alerts
```
Info:    Task completed successfully
Warning: Task running > 10 minutes
Critical: Task failed OR task stuck > 30 minutes
```

#### Agent Alerts
```
Info:    Agent active and healthy
Warning: Agent idle > 1 hour
Critical: Agent stuck (streaming but no progress) OR error state
```

#### System Alerts
```
Info:    Gateway connected, all systems normal
Warning: Gateway latency > 2s OR degraded performance
Critical: Gateway disconnected OR multiple errors in 5 min
```

### Alert Presentation Guidelines

1. **Don't alert for normalcy** — Only show alerts when something needs attention
2. **Be specific** — "3 tasks failed in the last hour" > "Some tasks failed"
3. **Offer next action** — Every critical alert should have a clickable fix
4. **Respect quiet hours** — Suppress non-critical alerts during off-hours (configurable)

---

## Suggested New Insights

### System Health Indicator (HIGH PRIORITY)

**Concept:** A single glanceable score (0-100) that answers "Is everything OK?"

**Visual Design:**
```
┌─ System Health ─────────────────────────────┐
│                                              │
│   ╭─────────────────────────────────────╮   │
│   │     🟢 HEALTH SCORE: 94/100         │   │
│   │                                     │   │
│   │  ✅ Gateway: Connected (lat 45ms)   │   │
│   │  ✅ Tasks: 0 failed / 12 total      │   │
│   │  ✅ Budget: $12 of $50 (24%)        │   │
│   │  ⚠️  Usage: 72% of Anthropic quota  │   │
│   │                                     │   │
│   ╰─────────────────────────────────────╯   │
│                                              │
│  [View Details]                              │
└──────────────────────────────────────────────┘
```

**Scoring Factors:**
- Gateway connectivity (30 points)
- Task success rate (25 points)
- Budget status (25 points)
- Provider quota status (20 points)

**Color Coding:**
- 🟢 80-100: Healthy (green)
- 🟡 60-79: Attention (yellow)
- 🔴 0-59: Problems (red)

**Actions Triggered:**
- Click score → expand to show details
- Critical state → show "Fix Issues" button
- Healthy state → show encouraging message

---

### Proactive Suggestions Widget (HIGH PRIORITY)

**Concept:** Dashboard actively suggests what user should do next

**Visual Design:**
```
┌─ Suggested Actions ──────────────────────────┐
│                                              │
│  🔴 3 tasks failed this morning              │
│     [Review failed tasks →]                  │
│                                              │
│  ⚠️ Approaching Anthropic quota limit (85%)  │
│     [View usage breakdown →]                 │
│                                              │
│  💡 You have 2 idle agents                   │
│     [Start new task →]                       │
│                                              │
└──────────────────────────────────────────────┘
```

**Suggestion Types:**

| Trigger | Suggestion | Priority |
|---------|------------|----------|
| Failed tasks > 0 | "Review N failed tasks" | Critical |
| Budget > 80% | "Review cost breakdown" | Warning |
| Quota > 85% | "Approaching limit" | Warning |
| Idle agents > 0 | "Start new task" | Info |
| No recent activity | "Everything looks good — start something new?" | Info |
| Gateway disconnected | "Reconnect to gateway" | Critical |
| Tasks stuck > 30m | "N tasks may be stuck" | Warning |

**Smart Context:**
- Show 3-5 most relevant suggestions
- Prioritize critical over info
- Don't show suggestion if action already taken
- Learn from user dismissals

---

### Enhanced Cost Tracking (MEDIUM PRIORITY)

**Current Problem:** Cost is just a number with no context

**Enhanced Design:**
```
┌─ Cost Tracking ──────────────────────────────┐
│                                              │
│  This Month: $12.45 / $50 budget             │
│  [████████░░░░░░░░░░░░░░░░░░] 25%           │
│                                              │
│  📊 Projected: $38 (under budget ✓)         │
│  📈 Trend: -15% vs last month               │
│                                              │
│  Top Costs:                                  │
│  • Anthropic/Opus: $8.20 (66%)              │
│  • OpenAI/GPT-4: $3.15 (25%)                │
│  • Other: $1.10 (9%)                        │
│                                              │
│  [Set Budget] [View Details →]              │
│                                              │
└──────────────────────────────────────────────┘
```

**New Features:**
1. **Budget progress bar** — Visual context for spending
2. **Monthly projection** — "On track to spend $X"
3. **Trend comparison** — "Up/down X% vs last month"
4. **Cost breakdown** — Top providers/models
5. **Budget setting** — Let user set alert thresholds

---

### Performance Dashboard (MEDIUM PRIORITY)

**Concept:** Metrics that help users optimize their usage

**Visual Design:**
```
┌─ Performance ────────────────────────────────┐
│                                              │
│  Response Time: 1.2s avg (▼ 0.3s vs week)   │
│  Token Efficiency: 85% (▲ 5%)               │
│  Cache Hit Rate: 42%                         │
│  Queue Depth: 0 pending                      │
│                                              │
│  Model Speed Ranking:                        │
│  1. Haiku — 0.4s avg                         │
│  2. Sonnet — 1.1s avg                        │
│  3. Opus — 2.8s avg                          │
│                                              │
└──────────────────────────────────────────────┘
```

**Metrics to Track:**
- Average response time (with trend)
- Token efficiency (useful tokens / total tokens)
- Cache utilization rate
- Queue depth (pending requests)
- Per-model performance comparison

**Why It Matters:**
- Helps users choose faster/cheaper models
- Identifies performance degradation
- Guides optimization decisions

---

## User Scenarios

### Scenario: Everything Working Well

**Dashboard State:**
- System Health: 🟢 96/100
- No alerts or warnings
- Cost trending under budget
- Tasks completing successfully

**What User Sees:**
```
┌──────────────────────────────────────────────┐
│  🟢 System Health: 96/100                    │
│                                              │
│  ✅ All systems operational                  │
│  ✅ 5 tasks completed successfully today     │
│  ✅ Budget on track ($12 of $50)             │
│                                              │
│  💡 Everything looks great!                  │
│     [Start new task] [View recent work →]   │
└──────────────────────────────────────────────┘
```

**User Learns:** "My OpenClaw is healthy, nothing needs attention."

**Action (if any):** Optional — user can start new work or review recent activity

**Emotional State:** Confident, relaxed ✅

---

### Scenario: Something Needs Attention

**Dashboard State:**
- System Health: 🟡 72/100
- 3 tasks failed
- Budget at 78%
- One agent idle 2+ hours

**What User Sees:**
```
┌──────────────────────────────────────────────┐
│  🟡 System Health: 72/100                    │
│                                              │
│  ⚠️ 3 issues need attention:                 │
│                                              │
│  🔴 3 tasks failed in last hour              │
│     [Review and retry →]                     │
│                                              │
│  ⚠️ Budget at 78% ($39 of $50)               │
│     [View cost breakdown →]                  │
│                                              │
│  💡 Agent "researcher" idle for 2h           │
│     [Assign new task →]                      │
└──────────────────────────────────────────────┘
```

**User Learns:** "I have 3 problems to address, here's what they are."

**Actions Available:**
1. Click "Review and retry" → go to failed tasks
2. Click "View cost breakdown" → understand spending
3. Click "Assign new task" → put idle agent to work

**Emotional State:** Aware, directed, in control ✅

---

### Scenario: Performance Degrading

**Dashboard State:**
- System Health: 🟡 68/100
- Response times increasing
- Cache hit rate dropping
- Queue depth building up

**What User Sees:**
```
┌──────────────────────────────────────────────┐
│  🟡 System Health: 68/100                    │
│                                              │
│  ⚠️ Performance degrading:                   │
│                                              │
│  📊 Response time up 40% (1.2s → 1.7s)       │
│     [View performance metrics →]             │
│                                              │
│  📉 Cache hit rate dropped to 28%            │
│     [Optimize cache settings →]              │
│                                              │
│  🔄 5 requests pending in queue              │
│     [Clear queue →]                          │
│                                              │
│  💡 Tip: Switching to Haiku could speed up   │
│     simple tasks by 3x                       │
└──────────────────────────────────────────────┘
```

**User Learns:** "Performance is degrading, here's what's happening and what to do."

**Investigation Path:**
1. Click "View performance metrics" → see detailed breakdown
2. Identify bottleneck (model? cache? network?)
3. Apply fix (switch model, clear queue, etc.)

**Fixes Available:**
- Switch to faster model for simple tasks
- Clear request queue
- Optimize cache settings
- Check network connectivity

**Emotional State:** Concerned but empowered ✅

---

## Implementation Recommendations

### Phase 1: Foundation (HIGH Priority)
**Goal:** Make dashboard answer "Is everything OK?" and "What should I do?"

| # | Recommendation | Effort | Impact |
|---|----------------|--------|--------|
| 1.1 | Add **System Health Indicator** widget | 2-3 days | ⭐⭐⭐⭐⭐ Critical |
| 1.2 | Add **Suggested Actions** widget | 2-3 days | ⭐⭐⭐⭐⭐ Critical |
| 1.3 | Enhance **Hero Metrics** with trends and thresholds | 1 day | ⭐⭐⭐⭐ High |
| 1.4 | Make **Agent Status** rows clickable → navigate to session | 0.5 days | ⭐⭐⭐⭐ High |

### Phase 2: Context & Alerts (MEDIUM Priority)
**Goal:** Add actionable context to existing data

| # | Recommendation | Effort | Impact |
|---|----------------|--------|--------|
| 2.1 | Add **cost budget** setting and projections | 1-2 days | ⭐⭐⭐⭐ High |
| 2.2 | Add **failed task alerts** with retry action | 1 day | ⭐⭐⭐⭐ High |
| 2.3 | Make **Notifications** clickable → navigate to source | 1 day | ⭐⭐⭐ Medium |
| 2.4 | Add **alert severity framework** (info/warning/critical) | 1 day | ⭐⭐⭐ Medium |

### Phase 3: Performance & Polish (LOWER Priority)
**Goal:** Optimize and refine

| # | Recommendation | Effort | Impact |
|---|----------------|--------|--------|
| 3.1 | Add **Performance Dashboard** widget | 2-3 days | ⭐⭐⭐ Medium |
| 3.2 | Add **stuck agent detection** (idle > threshold) | 1 day | ⭐⭐⭐ Medium |
| 3.3 | Add **activity log severity filtering** | 0.5 days | ⭐⭐ Low |
| 3.4 | Remove or contextualize **Uptime** metric | 0.5 days | ⭐⭐ Low |

---

## Appendix: Widget Actionability Summary

| Widget | Current Actionability | Primary Gap | Fix Priority |
|--------|----------------------|-------------|--------------|
| Tasks | ⭐⭐⭐ Medium | No failure alerts | HIGH |
| Agent Status | ⭐⭐⭐ Medium | No click-to-open | HIGH |
| Recent Sessions | ⭐⭐⭐⭐ High | Missing "new session" button | MEDIUM |
| Activity Log | ⭐⭐ Low-Medium | Errors don't stand out | MEDIUM |
| Usage Meter | ⭐⭐⭐ Medium | No budget alerts | HIGH |
| Skills | ⭐⭐ Low | No interaction | LOW |
| Notifications | ⭐⭐ Low | Can't act on them | MEDIUM |
| Hero Metrics | ⭐⭐ Low | No context/trends | HIGH |

---

## Conclusion

The ClawSuite dashboard successfully presents information but fails to guide action. Users must:

1. **Mentally compute** what metrics mean ("Is $12 good?")
2. **Hunt for next steps** (no suggested actions)
3. **Notice problems themselves** (no proactive alerts)
4. **Navigate manually** to take action (many dead-end widgets)

**The Fix:** Transform dashboard from "status display" → "action center" by adding:
- System health score (answer "Is everything OK?")
- Suggested actions (answer "What should I do?")
- Alert thresholds (surface problems proactively)
- Click-through actions (every widget leads somewhere)

**Success Metric:** User opens dashboard and within 5 seconds can answer:
1. ✅ Is everything working? (Health score)
2. ✅ What's happening? (Active work visible)
3. ✅ Do I need to do anything? (Alerts + suggestions)
4. ✅ What should I click? (Clear CTAs)

---

**Report Complete** — Ready for Pass 3 (Visual Design) and Pass 4 (Data Validation)
