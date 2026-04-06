# Implementation Plan: Phase 3 — Dashboard Core

**Branch**: `003-dashboard-core` | **Date**: 2026-04-05 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/003-dashboard-core/spec.md`

## Summary

Create `dashboard.html` — a new second page for the app. It has a PIN gate screen that hashes the entered PIN and compares it against the stored hash in the `settings` table. Once authenticated, the admin sees a full staff management interface: list all staff (active + inactive), real-time search, add via modal, edit name via modal, and soft-delete with confirmation.

The existing `booth-attendance.html` (attendance page) is not touched in this phase.

## Technical Context

**Language/Version**: Vanilla JavaScript (ES2020+, async/await), no build step  
**Primary Dependencies**: Supabase JS client v2 (CDN), `config.js` (credentials), Web Crypto API (SHA-256 hashing), Google Fonts (Tajawal)  
**Storage**: Supabase — `settings` table (PIN hash read), `staff` table (full CRUD)  
**Testing**: Manual browser testing; no automated test framework  
**Target Platform**: Modern web browser (desktop + mobile); file opened locally or served from Netlify  
**Project Type**: Single-file web application — `dashboard.html` (new file, same pattern as `booth-attendance.html`)  
**Performance Goals**: Staff list loads in under 2s after PIN unlock; add/edit/delete completes in under 2s  
**Constraints**: No build system, no Node.js, no framework; all logic inline in `dashboard.html`; RTL Arabic UI  
**Scale/Scope**: ~50 staff members; single admin user per session

## Constitution Check

**Constitution status**: Unfilled template — no project-specific principles ratified. No gates apply.

**Post-design re-check**: No violations. New file follows the same single-file pattern established in Phase 2.

## Project Structure

### Documentation (this feature)

```text
specs/003-dashboard-core/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (JS function contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
dashboard.html           ← NEW FILE — entire dashboard (CSS + HTML + JS)
booth-attendance.html    ← UNCHANGED in this phase
config.js                ← Unchanged
config.example.js        ← Unchanged
supabase/                ← Unchanged
```

**Structure Decision**: One new file, same single-file pattern as `booth-attendance.html`. No shared CSS/JS files — each page is self-contained for simplicity (Netlify static deployment).

## Complexity Tracking

> No constitution violations to justify.
