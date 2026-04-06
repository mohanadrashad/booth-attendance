# Implementation Plan: Phase 4 — Events & Attendance Overview

**Branch**: `004-events-attendance` | **Date**: 2026-04-05 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/004-events-attendance/spec.md`

## Summary

Extend `dashboard.html` with two new sections: **Events** (create, edit, activate, delete events) and **Attendance** (table view of check-ins per event, late flags, stats). Navigation between Staff / Events / Attendance uses a tab pattern within the same page. No new HTML files. Also adds an optional `start_time` column to the `events` table via a new migration.

## Technical Context

**Language/Version**: Vanilla JavaScript (ES2020+, async/await), no build step  
**Primary Dependencies**: Supabase JS client v2 (CDN), `config.js` (credentials), Google Fonts (Tajawal)  
**Storage**: Supabase — `events` table (full CRUD + new `start_time` column), `attendance` table (read-only queries with staff join), `staff` table (count query for stats)  
**New Migration**: Add `start_time TIME` column to `events` table (nullable)  
**Testing**: Manual browser testing; no automated test framework  
**Target Platform**: Modern web browser (desktop + mobile); existing `dashboard.html`  
**Project Type**: Extends existing single-file `dashboard.html` — adds tab navigation + two new section views  
**Performance Goals**: Attendance table loads in under 3s; event list loads in under 2s  
**Constraints**: No build system; all changes in `dashboard.html` + one new migration SQL file; RTL Arabic UI; max 200 rows in attendance table

## Constitution Check

**Constitution status**: Unfilled template — no gates apply.  
**Post-design re-check**: No violations. Extends existing file with consistent patterns.

## Project Structure

### Documentation (this feature)

```text
specs/004-events-attendance/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code Changes

```text
dashboard.html                              ← Extended with Events + Attendance sections
supabase/migrations/002_events_start_time.sql  ← NEW: adds start_time column to events
booth-attendance.html                       ← UNCHANGED
```

## Complexity Tracking

> No constitution violations to justify.
