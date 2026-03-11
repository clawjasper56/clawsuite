# ClawSuite Dashboard — UX Review & Polish Plan
**Created:** 2026-02-22  
**Objective:** Deliver immediate "so what" value when users open the dashboard

---

## Problem Statement

**Current state:** Dashboard shows metrics and widgets, but lacks clear narrative and actionable insights.

**Goal:** User opens dashboard → immediately understands:
1. **Health:** Is OpenClaw working well?
2. **Status:** What's happening right now?
3. **Attention:** What needs my attention?
4. **Action:** What should I do next?

---

## Multi-Pass Review Strategy

### Pass 1: Information Architecture (Planner)
**Focus:** "What story does this dashboard tell?"

**Questions:**
- Is the most important information at the top?
- Does the visual hierarchy match the importance hierarchy?
- Are we showing the right metrics?
- What's missing?
- What's noise?

**Deliverable:** Information architecture recommendations

---

### Pass 2: Actionable Insights (Researcher)
**Focus:** "What decisions can users make from this data?"

**Questions:**
- Which metrics lead to actions?
- Where are the dead-ends (data with no next step)?
- What alerts/thresholds would add value?
- How do we surface problems proactively?
- What's the "happy path" vs "something's wrong" path?

**Deliverable:** Actionable insight recommendations

---

### Pass 3: Visual Design Pass (Coder - UI/UX focus)
**Focus:** "Does this feel polished and professional?"

**Questions:**
- Visual hierarchy clear?
- Colors/spacing consistent?
- Information density appropriate?
- Mobile responsive?
- Accessibility (color contrast, screen readers)?
- Animations/transitions smooth?

**Deliverable:** Visual polish improvements

---

### Pass 4: Data Validation (QA mindset)
**Focus:** "Is the data accurate and trustworthy?"

**Questions:**
- Are APIs returning correct data?
- Edge cases handled (loading, errors, empty states)?
- Stale data detection?
- Refresh logic working?
- Cost calculations accurate?

**Deliverable:** Data integrity validation + fixes

---

## Current Dashboard Analysis

### Hero Metrics (Top Bar)
**Current:**
1. Total Sessions
2. Active Agents
3. Uptime
4. Cost

**Questions to answer:**
- Is "Total Sessions" useful? (Or just "Active Sessions"?)
- "Active Agents" — what does this number mean to user?
- Uptime — uptime of what? Gateway? Main session?
- Cost — is this today? Month? All-time?

**Missing insights:**
- Are things working well? (Error rate, success rate)
- Performance metrics (response time, token efficiency)
- Trend indicators (up/down arrows, % change)

---

### Available Widgets
**Current:**
- Skills Widget
- Usage Meter Widget
- Tasks Widget
- Agent Status Widget
- Recent Sessions Widget
- Notifications Widget
- Activity Log Widget

**Questions:**
- Which widgets provide actionable insights?
- Which are just "nice to have"?
- What critical info is missing?

---

## Key "So What" Scenarios

### Scenario 1: Everything Working Great
**User opens dashboard, sees:**
- ✅ Green status indicators
- ✅ Recent successful tasks
- ✅ Cost under budget
- ✅ No errors or alerts

**So what:** "My OpenClaw is healthy, nothing needs my attention right now."

---

### Scenario 2: Something Needs Attention
**User opens dashboard, sees:**
- ⚠️ Yellow alert: 3 failed tasks in last hour
- ⚠️ Cost trending 20% over budget this month
- ⚠️ One agent stuck for 15 minutes

**So what:** "I need to check failed tasks, review cost, and investigate stuck agent."

---

### Scenario 3: First-Time User
**User opens dashboard, sees:**
- ❓ "What is this?"
- ❓ "What should I click?"
- ❓ "How do I get value from this?"

**So what:** Need onboarding flow or better labels/tooltips.

---

## Proposed Information Hierarchy (Draft)

### 1. System Health (Glanceable)
**Top priority — always visible**
- Gateway status (connected/disconnected)
- Error rate (0 errors / 3 errors in last hour)
- Performance indicator (fast/slow/degraded)

### 2. What's Happening Right Now (Real-Time)
**Second priority — active work status**
- Active agents count + status
- Current tasks (running/queued/blocked)
- Recent activity feed

### 3. What Needs Attention (Alerts)
**Third priority — actionable items**
- Failed tasks
- Stuck agents
- Budget alerts
- Warnings/errors

### 4. Historical Context (Trends)
**Fourth priority — understanding patterns**
- Cost over time
- Token usage trends
- Success/failure rates
- Session history

### 5. Navigation/Actions (Tools)
**Always accessible**
- Start new chat
- View all sessions
- Manage agents
- Settings

---

## Specific Dashboard Improvements (Candidates)

### Hero Metrics Enhancement
**Add trend indicators:**
```
Active Agents: 3 ↑ (+2 since yesterday)
Cost: $12.45 ↓ (-15% vs last week)
Success Rate: 95% ↑ (+3%)
```

**Add color coding:**
- Green: within budget, high success rate
- Yellow: warning thresholds
- Red: critical issues

---

### Add "At a Glance" Health Card
**New widget priority: HIGH**

```
┌─ System Health ─────────────────┐
│ ✅ Gateway: Connected            │
│ ✅ Error Rate: 0 in last hour    │
│ ✅ Performance: Normal            │
│ ✅ Budget: On track ($12/$50)    │
└─────────────────────────────────┘
```

---

### Enhance Tasks Widget
**Current:** Just lists tasks  
**Improved:** Show task outcomes + next actions

```
┌─ Recent Tasks ──────────────────┐
│ ✅ Security audit (completed 2m) │
│ 🔄 Code review (in progress 5m)  │
│ ❌ Test suite (failed - view)    │ ← Clickable
│ ⏸️ Deploy (blocked on approval)  │ ← Actionable
└─────────────────────────────────┘
```

---

### Add "Next Steps" Widget
**New widget priority: MEDIUM**

Proactive suggestions based on current state:
```
┌─ Suggested Actions ─────────────┐
│ • Review 3 failed tasks from     │
│   morning run                    │
│ • Agent "researcher" idle 30m    │
│   — consider new task            │
│ • Cost tracking: you're ahead of │
│   budget this week!              │
└─────────────────────────────────┘
```

---

### Improve Cost Widget
**Current:** Just total spend  
**Improved:** Context + trends

```
┌─ Cost Tracking ─────────────────┐
│ Today: $12.45                    │
│ This Month: $38.20 / $50 budget  │
│ Projection: $45 (under budget)   │
│ Trend: ↓ 15% vs last month       │
└─────────────────────────────────┘
```

---

### Add Performance Metrics Widget
**New widget priority: HIGH**

```
┌─ Performance ───────────────────┐
│ Avg Response: 1.2s               │
│ Token Efficiency: 85% ↑          │
│ Cache Hit Rate: 42%              │
│ Queue Depth: 0                   │
└─────────────────────────────────┘
```

---

## Open Questions for Review Passes

1. **Should we show model selection on dashboard?**
   - Pro: Quick model switching
   - Con: Adds complexity to top bar

2. **Should agent status be prominent or buried in widget?**
   - Currently in widget (can be hidden)
   - Maybe should be always-visible?

3. **What does "Active Agents" mean to end user?**
   - Sub-agents spawned?
   - Sessions with recent activity?
   - Needs clarification

4. **Is Activity Ticker useful or distracting?**
   - Real-time events scrolling by
   - Depends on update frequency

5. **Should we have a "Quick Start" section for new users?**
   - "Start a chat"
   - "Spawn an agent"
   - "View documentation"

---

## Success Criteria

**User opens dashboard and within 5 seconds can answer:**
1. ✅ Is everything working? (Health status)
2. ✅ What's happening right now? (Active work)
3. ✅ Do I need to do anything? (Alerts/actions)
4. ✅ How am I tracking on budget? (Cost context)

**Stretch goal:**
- Dashboard suggests next action ("Review failed tasks" / "All good, start new work")

---

## Next Steps

1. **Pass 1 (Planner):** Review information architecture
2. **Pass 2 (Researcher):** Identify actionable insights
3. **Pass 3 (Coder):** Visual design polish
4. **Pass 4 (QA):** Data validation + edge cases
5. **Chris review:** Final UX validation before OSS release

---

**Timeline:** Complete all passes before Chris testing after work today.
