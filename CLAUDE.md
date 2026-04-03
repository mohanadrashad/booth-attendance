# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-file Arabic RTL booth attendance tracking web app (`booth-attendance.html`). No build system, no package manager, no dependencies beyond Google Fonts (Tajawal). Run by opening the HTML file directly in a browser.

## Architecture

The entire application lives in one file with three sections:
- **CSS** (lines 1–490 approx): Dark-mode theme using CSS variables, RTL layout, responsive flexbox/grid
- **HTML** (middle): Minimal shell — stats bar, staff grid container, modal overlay, toast container
- **JavaScript** (bottom ~200 lines): All app logic in a single inline `<script>` block

### State

All state is in-memory with no persistence:
- `STAFF` array (hardcoded) — source of truth for staff members
- `attendance` object — keyed by `staffId`, stores `{ time, signature, timestamp }` per check-in

### Data Flow

```
Staff card click → openModal(id) → canvas signature draw
→ confirmAttendance() → updates attendance{} → renderStaff() + updateStats()
```

### Key Functions

| Function | Purpose |
|---|---|
| `init()` | Entry point, called on page load |
| `renderStaff()` | Re-renders full staff grid from STAFF + attendance state |
| `updateStats()` | Updates present/absent counters |
| `openModal(id)` / `closeModal()` | Signature capture modal |
| `confirmAttendance()` | Writes to attendance{}, triggers re-render |
| `exportData()` | Generates text report, uses Web Share API with Clipboard fallback |
| `resetAll()` | Clears attendance{} with confirmation |

## Customization

To modify the staff list, edit the `STAFF` array near the bottom of the `<script>` block:
```javascript
const STAFF = [
  { id: 1, name: 'أحمد العتيبي' },
  // add/remove entries here
];
```

To change the color theme, edit the CSS variables at the top of the `<style>` block (`:root { --accent: #10b981; ... }`).

## Constraints

- **No persistence** — attendance data resets on page refresh by design
- **Arabic/RTL only** — UI text is hardcoded in Arabic; layout uses `dir="rtl"`
- **Signature required** — the confirm button stays disabled until the canvas has been drawn on (`hasDrawn` flag)
- **Single-present rule** — clicking a card that already has attendance does nothing (card gets `pointer-events: none`)
