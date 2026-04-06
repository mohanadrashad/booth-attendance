# Implementation Plan: Phase 2 — Attendance Page (DB Connected)

**Branch**: `002-attendance-page-db` | **Date**: 2026-04-05 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/002-attendance-page-db/spec.md`

## Summary

Replace the hardcoded in-memory data layer in `booth-attendance.html` with live Supabase queries. On load, the page fetches active staff, active event, and existing attendance records from the database. Check-ins are written to the database in real time. The existing CSS, HTML structure, and UX remain unchanged — only the JavaScript data layer is replaced.

## Technical Context

**Language/Version**: Vanilla JavaScript (ES2020+, async/await), no build step  
**Primary Dependencies**: Supabase JS client v2 (CDN), `config.js` (credentials), Google Fonts (Tajawal)  
**Storage**: Supabase (Phase 1 schema — `staff`, `events`, `attendance` tables)  
**Testing**: Manual browser testing; no automated test framework  
**Target Platform**: Modern web browser; file opened locally or served from Netlify  
**Project Type**: Single-file web application (all logic inline in `booth-attendance.html`)  
**Performance Goals**: Full page load (staff + event + attendance hydration) under 3s; check-in save under 2s  
**Constraints**: No build system, no Node.js, no framework; all changes confined to the `<script>` block and `<head>` of `booth-attendance.html`  
**Scale/Scope**: ~50 staff, single active event at a time, ~500 attendance records per event

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution status**: Unfilled template — no project-specific principles ratified. No gates apply.

**Post-design re-check**: No violations. All changes are confined to a single file with no new dependencies beyond the Supabase CDN already established in the project plan.

## Project Structure

### Documentation (this feature)

```text
specs/002-attendance-page-db/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (JS state shapes)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (JS function contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
booth-attendance.html    ← ALL changes go here (head + script block only)
config.js                ← Credentials (created in Phase 1, not modified)
config.example.js        ← Template (not modified)
supabase/                ← Phase 1 SQL files (not modified)
```

**Structure Decision**: Single file. No new files are created. The entire implementation is a targeted rewrite of the `<script>` block and a two-line addition to `<head>` in `booth-attendance.html`.

## Complexity Tracking

> No constitution violations to justify.
