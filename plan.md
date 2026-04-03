# Booth Attendance — Dashboard Upgrade

## Summary

The current Booth Attendance tool is a single HTML file with hardcoded staff, signature-based check-in, and no data persistence. This upgrade converts it into a two-page Netlify app backed by Supabase (PostgreSQL), adding a PIN-protected admin dashboard with full staff management, event management, attendance tracking, and export capabilities.

**Stack:** Supabase + Vanilla JS + Netlify
**Pages:** `index.html` (attendance) — `dashboard.html` (admin)
**Auth:** 4-digit PIN lock on dashboard (SHA-256 hashed in DB)

---

## Phases

### Phase 1 — Database Setup
- Create Supabase project and configure `config.js`
- Build schema: `staff`, `events`, `attendance`, `settings` tables
- Set up RLS policies and seed sample data

### Phase 2 — Attendance Page (DB Connected)
- Replace hardcoded staff array with Supabase queries
- Load active event from DB
- Save attendance records + signatures to DB in real-time

### Phase 3 — Dashboard Core
- PIN gate screen with hashed verification
- Staff CRUD: add, edit, soft-delete, search/filter
- Modal forms for staff creation and editing

### Phase 4 — Events + Attendance Overview
- Event creation, switching, and history
- Attendance table with event/date filters
- Late arrival flags and attendance rate stats

### Phase 5 — Export + Settings
- CSV, PDF (with signatures), and text export
- Date/event filtering before export
- Settings panel: PIN change, theme toggle, language toggle