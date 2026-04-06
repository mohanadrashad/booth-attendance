# Research: Phase 4 — Events & Attendance Overview

**Date**: 2026-04-05  
**Branch**: `004-events-attendance`

---

## 1. Tab Navigation Pattern — Section Switching Within `dashboard.html`

**Decision**: Add a tab bar below the dashboard header with three tabs: "الموظفون" (Staff), "الفعاليات" (Events), "الحضور" (Attendance). Clicking a tab hides all section divs and shows only the selected one. Active tab has a visual accent underline. Navigation state is held in a module-level `activeTab` variable.

```js
let activeTab = 'staff'; // 'staff' | 'events' | 'attendance'

function switchTab(tab) {
  activeTab = tab;
  document.querySelectorAll('.tab-section').forEach(el => el.classList.add('hidden'));
  document.getElementById(`section-${tab}`).classList.remove('hidden');
  document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
  document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
  if (tab === 'events') loadEvents();
  if (tab === 'attendance') loadAttendance();
}
```

**Rationale**: Zero new files. Consistent with the single-file architecture already used for the Staff section. Tabs are the standard mobile-first pattern for multi-section dashboards.

**Alternatives considered**:
- Separate `events.html` and `attendance.html` pages: Breaks the single-file architecture; each would need to re-implement PIN auth; rejected.
- Accordion/collapsible sections: Harder to navigate on mobile; rejected.
- URL hash-based routing (`#events`): Adds complexity without benefit for 3 sections; rejected.

---

## 2. `events` Table — Adding `start_time` Column

**Decision**: Add a nullable `TIME` column `start_time` to the `events` table via a new migration. Default `NULL` means no late-flag logic for that event.

```sql
-- supabase/migrations/002_events_start_time.sql
ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT NULL;
```

**Rationale**: `TIME` (no date, no timezone) is the correct type — late detection compares only the time-of-day portion of `checked_in_at` with the event's `start_time`. The existing Phase 1 schema is extended non-destructively.

**Alternatives considered**:
- `TIMESTAMPTZ` for start_time: Overkill — we only care about time of day, not an absolute moment; rejected.
- Store start_time as a string (HH:MM): No type safety; rejected.
- Add a separate `event_settings` table: Unnecessary complexity for one nullable field; rejected.

---

## 3. Atomic "Activate Event" — Single DB Update

**Decision**: When activating an event, use two sequential Supabase calls:
1. `UPDATE events SET is_active = false WHERE is_active = true` — deactivate all
2. `UPDATE events SET is_active = true WHERE id = $eventId` — activate the target

This is simple, readable, and safe for the app's single-admin, single-event-at-a-time model. No need for a database transaction or stored procedure.

**Rationale**: The window between the two updates is negligible (milliseconds) and no other client is racing to change the active event. A brief moment where no event is active is acceptable and won't corrupt data.

**Alternatives considered**:
- Supabase RPC (stored procedure) for atomic swap: Cleaner for high-concurrency, but adds server-side code complexity; overkill here; rejected.
- Single `UPDATE ... CASE WHEN ...` statement: Possible but less readable; not needed at this scale; rejected.

---

## 4. Attendance Table — Joining Staff Names Client-Side

**Decision**: Query attendance records with a Supabase join to get the staff name in one request:

```js
const { data } = await _supabase
  .from('attendance')
  .select('id, checked_in_at, staff:staff_id(name), event_id')
  .eq('event_id', selectedEventId)
  .order('checked_in_at')
  .limit(200);
```

Supabase's PostgREST syntax supports embedded resource selects (`staff:staff_id(name)`), which performs a JOIN server-side and returns `{ staff: { name: '...' } }` per row.

**Rationale**: Single network round-trip. No need to build a manual join client-side. The 200-row limit from the spec assumption is enforced here.

**Alternatives considered**:
- Separate query for staff names + client-side join: Two round-trips, manual join logic; rejected.
- Materialised view: No DDL access needed; overkill; rejected.

---

## 5. Late Arrival Detection — Client-Side Time Comparison

**Decision**: Detect late arrivals client-side after fetching attendance records. Extract the time portion from `checked_in_at`, compare with `event.start_time` (HH:MM string).

```js
function isLate(checkedInAt, startTime) {
  if (!startTime) return false;
  const checkin = new Date(checkedInAt);
  const [h, m] = startTime.split(':').map(Number);
  const start = new Date(checkin);
  start.setHours(h, m, 0, 0);
  return checkin > start;
}
```

**Rationale**: No extra DB computation needed. The comparison is simple and fast client-side. Works correctly with the browser's local timezone since `checked_in_at` is a UTC ISO string and `new Date()` converts to local time automatically.

**Alternatives considered**:
- Server-side late flag stored in `attendance` table: Adds complexity; the flag would need to be re-computed if start_time changes; rejected.
- Supabase computed column: Requires DDL changes and a function; overkill; rejected.

---

## 6. Attendance Stats — Single Aggregated Query

**Decision**: Compute stats from data already loaded in memory. After loading attendance for the selected event and the full active staff list, stats are computed client-side:

```js
function computeStats(staff, attendance) {
  const total = staff.filter(s => s.is_active).length;
  const present = attendance.length;
  const absent = total - present;
  const rate = total === 0 ? 0 : Math.round((present / total) * 100);
  return { total, present, absent, rate };
}
```

The `staff` array is already loaded from the Staff tab (Phase 3). Reuse it — no extra query.

**Rationale**: Data is already in memory. Zero extra DB round-trips. Works correctly: only active staff are counted in the denominator (spec FR-014).

**Alternatives considered**:
- Supabase COUNT query per stat: Multiple round-trips; stats would lag slightly behind; rejected.
- Store stats in a separate DB table: Premature optimisation at this scale; rejected.

---

## 7. Event Deletion Guard — Check Before Delete

**Decision**: Before deleting an event, query `COUNT(*) FROM attendance WHERE event_id = $id`. If count > 0, block deletion and show error message. If 0, show confirmation prompt then DELETE.

```js
async function deleteEvent(eventId) {
  const { count } = await _supabase
    .from('attendance')
    .select('*', { count: 'exact', head: true })
    .eq('event_id', eventId);

  if (count > 0) {
    showToast('❌ لا يمكن حذف فعالية لها سجلات حضور', true);
    return;
  }
  // show inline confirm then DELETE
}
```

**Rationale**: Using `{ count: 'exact', head: true }` fetches only the count with no data — minimal bandwidth. Clean UX: the error message explains why deletion is blocked without a confusing DB error.

**Alternatives considered**:
- FK ON DELETE RESTRICT at DB level: Already in Phase 1 schema! This client-side check provides a user-friendly error message before hitting the constraint; both layers are now active (defense in depth).

---

## 8. Events Section — New RLS Migration

**Decision**: The `events` table currently only has anon SELECT. The dashboard needs INSERT, UPDATE, and DELETE. Add these in a new migration.

```sql
-- supabase/migrations/003_events_dashboard_rls.sql
CREATE POLICY "anon can insert events"
  ON events FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update events"
  ON events FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can delete events"
  ON events FOR DELETE TO anon USING (true);
```

Same security model as Phase 3 staff writes: PIN gate is the access control layer.

**Rationale**: Consistent with the Phase 3 pattern for staff writes. No service-role key in browser.

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| Navigation | Tab bar in `dashboard.html` — `switchTab()` toggles section visibility |
| `start_time` column | `ALTER TABLE events ADD COLUMN start_time TIME DEFAULT NULL` |
| Activate event | Two sequential UPDATEs (deactivate all → activate target) |
| Attendance join | Supabase embedded `staff:staff_id(name)` select, 200-row limit |
| Late detection | Client-side time comparison after data load |
| Stats | Client-side from already-loaded staff + attendance arrays |
| Delete guard | Client-side count check + DB FK constraint (defense in depth) |
| Events RLS | New migration: anon INSERT, UPDATE, DELETE on events |
