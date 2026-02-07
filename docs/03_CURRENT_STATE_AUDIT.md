# Current Development State Audit

> Last updated: 2026-02-07

## Fully Wired (Real Gateway Data)

- Chat (send, stream, history)
- Session list + switching + title resolution
- Terminal (real PTY via Gateway WebSocket)
- File Explorer (read/write with Monaco editor)
- Skills Browser (2,070+ from ClawdHub registry)
- Cron Manager (list, toggle, run, view runs)
- Gateway persistent singleton connection (auto-reconnect + heartbeat)

## Partially Wired

- Dashboard widgets (weather=real, sessions=real, status=partial)
- Agent sidebar (real sessions, demo fallback for swarm view)
- Provider usage (API exists, requires env var API keys)
- Memory viewer (reads real files, some mock structure)

## Visual Only (Not Wired)

- Model switcher (dropdown exists, doesn't send to Gateway)
- Voice/TTS (mic button exists, no functionality)
- Utility buttons (+, globe, flash, code — no actions)
- Usage meter (donut chart with demo data)
- Cost tracker (sparkline with demo data)
- Tasks kanban board (localStorage only, not Gateway-connected)
- Activity logs (waiting on Gateway event stream API)
- Settings persistence (UI exists, doesn't apply to Gateway)
- Dashboard drag-and-drop (buttons exist, no react-grid-layout)
