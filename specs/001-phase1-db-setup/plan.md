# Implementation Plan: Phase 1 — Data Foundation

**Branch**: `001-phase1-db-setup` | **Date**: 2026-04-03 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/001-phase1-db-setup/spec.md`

## Summary

Establish the persistent data storage foundation for the Booth Attendance application by creating a hosted PostgreSQL database with four core tables (staff, events, attendance, settings), row-level access controls, and idempotent seed data. This enables all subsequent phases to replace the current in-memory, hardcoded approach with durable, queryable records.

## Technical Context

**Language/Version**: Vanilla JavaScript (ES2020+), no build step  
**Primary Dependencies**: Supabase JS client v2 (CDN), Google Fonts (Tajawal), Web Crypto API (built-in browser)  
**Storage**: Supabase (hosted PostgreSQL) — accessed via Supabase JS client from the browser  
**Testing**: Manual browser testing + Supabase SQL editor verification; no automated test framework  
**Target Platform**: Modern web browser; hosted on Netlify (static files only)  
**Project Type**: Web application (multi-page static, no server runtime)  
**Performance Goals**: Page load under 2s on a 4G connection; check-in write confirmed within 1s  
**Constraints**: No build system, no Node.js runtime, no server-side code; all DB access from browser via Supabase anon key scoped by RLS  
**Scale/Scope**: ~50 staff members, ~20 events per year, ~500 attendance records per event

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution status**: The `.specify/memory/constitution.md` file contains only the unfilled template — no project-specific principles have been ratified. No constitution gates apply.

**Post-design re-check**: No violations identified. The design follows the project's established constraints (single-file → multi-page vanilla JS, no build system, no server runtime, Supabase for persistence).

## Project Structure

### Documentation (this feature)

```text
specs/001-phase1-db-setup/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Supabase table contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
booth-attendance.html        # Existing attendance page (to be replaced in Phase 2)
dashboard.html               # New admin dashboard (Phase 3+)
config.js                    # Supabase credentials (NOT committed to source control)
config.example.js            # Template for config.js (committed)
supabase/
├── schema.sql               # Full schema: tables, constraints, RLS policies
└── seed.sql                 # Idempotent seed data (staff + default event + settings)
```

**Structure Decision**: Single flat structure at the repo root. No `src/` directory needed — this is a no-build static web app. SQL files live in a `supabase/` folder for clarity. JavaScript is inline in the HTML files.

## Complexity Tracking

> No constitution violations to justify.
