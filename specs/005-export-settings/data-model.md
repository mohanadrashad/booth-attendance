# Data Model: Phase 5 — Export & Settings

**Date**: 2026-04-05  
**Branch**: `005-export-settings`

---

## No New Tables

Phase 5 adds no new database tables. All required data already exists in the Phase 1 schema.

---

## Existing Tables Used

### `attendance`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `staff_id` | UUID FK → staff | Used to JOIN staff name |
| `event_id` | UUID FK → events | Filter for export by event |
| `checked_in_at` | TIMESTAMPTZ | Displayed as check-in time in all export formats |
| `signature_data` | TEXT | Full data URI (`data:image/png;base64,...`). Used as `<img src>` in PDF print window. May be NULL — render blank cell if so. |
| `created_at` | TIMESTAMPTZ | Not used in export output |

**Query for export**:
```sql
SELECT a.checked_in_at, a.signature_data, s.name AS staff_name
FROM attendance a
JOIN staff s ON s.id = a.staff_id
WHERE a.event_id = :eventId
ORDER BY a.checked_in_at ASC
```

---

### `settings`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Always 1 (single row) |
| `pin_hash` | TEXT | SHA-256 hex digest of the 4-digit PIN. Read for PIN verification; updated on PIN change. |
| `theme` | TEXT | `'dark'` or `'light'`. Present in schema but **not used for storage** — theme is stored in `localStorage` per device. This column is reserved for future multi-device sync. |
| `language` | TEXT | `'ar'`. Not used in Phase 5 (language toggle is out of scope). |
| `updated_at` | TIMESTAMPTZ | Not used in Phase 5 |

**Read query** (PIN verification):
```sql
SELECT pin_hash FROM settings WHERE id = 1
```

**Update query** (PIN change):
```sql
UPDATE settings SET pin_hash = :newHash WHERE id = 1
```

---

### `events`

Used by the export section to populate the event selector dropdown. No new queries beyond what Phase 4 already loads into `EVENTS[]`.

| Column | Used In Phase 5 |
|--------|----------------|
| `id` | Export event selector value |
| `name` | Export selector label; PDF/CSV/TXT filename; report header |
| `event_date` | Shown in text report header and PDF header |
| `is_active` | Mark active event with ● in export selector |

---

### `staff`

Not directly queried in Phase 5 — staff names come from the `attendance` JOIN. `STAFF[]` (already in memory) is used only by `renderAttendanceStats()` in Phase 4.

---

## New Migration Required

### `supabase/migrations/004_settings_dashboard_rls.sql`

The `settings` table currently only has anon SELECT. PIN change requires anon UPDATE.

```sql
CREATE POLICY "anon can update settings"
  ON settings FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
```

**Security note**: This follows the same pattern as Phase 3 (staff writes) and Phase 4 (events writes). The dashboard PIN gate is the security layer — only an authenticated admin reaches the Settings tab. The anon RLS policy is consistent with how all dashboard write operations are handled throughout this project.

---

## State Variables Added to `dashboard.html`

| Variable | Type | Purpose |
|----------|------|---------|
| `exportSelectedEventId` | string \| null | Which event is selected in the Export tab selector |
| `exportRecordCount` | number | Preview count shown before export buttons |

No new persistent state — theme is in `localStorage`, all other data comes from existing `EVENTS[]` and `ATTENDANCE[]` (or fresh fetch for export).
