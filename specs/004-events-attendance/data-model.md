# Data Model: Phase 4 — Events & Attendance Overview

**Date**: 2026-04-05  
**Branch**: `004-events-attendance`

---

## New SQL Migrations Required

### `supabase/migrations/002_events_start_time.sql`
```sql
ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT NULL;
```

### `supabase/migrations/003_events_dashboard_rls.sql`
```sql
CREATE POLICY "anon can insert events"
  ON events FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update events"
  ON events FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can delete events"
  ON events FOR DELETE TO anon USING (true);
```

---

## Extended Entity: `events`

Phase 1 schema + new `start_time` column:

| Field        | Type        | Nullable | Used For                                      |
|--------------|-------------|----------|-----------------------------------------------|
| `id`         | UUID        | No       | PK, FK from attendance                        |
| `name`       | TEXT        | No       | Display name in events list and header        |
| `event_date` | DATE        | No       | Shown in events list and attendance header    |
| `is_active`  | BOOLEAN     | No       | Only one event active at a time               |
| `start_time` | TIME        | Yes      | Late arrival threshold (NULL = no late flags) |
| `created_at` | TIMESTAMPTZ | No       | Auto-generated                                |

**Queries used**:
- Load all events: `SELECT id, name, event_date, is_active, start_time FROM events ORDER BY event_date DESC`
- Activate: `UPDATE events SET is_active=false WHERE is_active=true` then `UPDATE events SET is_active=true WHERE id=$id`
- Insert: `INSERT INTO events (name, event_date, start_time) VALUES (...) RETURNING *`
- Update: `UPDATE events SET name=$n, event_date=$d, start_time=$t WHERE id=$id RETURNING *`
- Delete guard: `SELECT count(*) FROM attendance WHERE event_id=$id` (head only)
- Delete: `DELETE FROM events WHERE id=$id`

---

## Read-Only Entity: `attendance` (dashboard view)

| Field            | Type        | Used For                                       |
|------------------|-------------|------------------------------------------------|
| `id`             | UUID        | Row key                                        |
| `staff_id`       | UUID        | FK join to get staff name                      |
| `event_id`       | UUID        | Filter by selected event                       |
| `checked_in_at`  | TIMESTAMPTZ | Display time; late detection against start_time |
| `staff.name`     | TEXT        | Joined via `staff:staff_id(name)`              |

**Query**: 
```js
_supabase
  .from('attendance')
  .select('id, checked_in_at, staff:staff_id(name)')
  .eq('event_id', selectedEventId)
  .order('checked_in_at')
  .limit(200)
```

---

## Module-Level State Variables (additions to `dashboard.html`)

```js
let EVENTS = [];           // [{ id, name, event_date, is_active, start_time }]
let selectedEventId = null; // UUID — event currently shown in attendance tab
let ATTENDANCE = [];        // [{ id, checked_in_at, staff: { name } }] for selectedEventId
```

`STAFF` is already loaded from Phase 3 — reused for stats denominator.

---

## State Transitions

### Events Tab

```
switchTab('events')
  ↓
loadEvents() → EVENTS[] populated → renderEventsList()

Create event
  openEventModal('add') → submit → INSERT → push to EVENTS[] → sort → renderEventsList()

Edit event
  openEventModal('edit', event) → submit → UPDATE → update EVENTS[] → renderEventsList()

Activate event
  activateEvent(id)
  ↓ UPDATE is_active=false WHERE is_active=true
  ↓ UPDATE is_active=true WHERE id=$id
  ↓ Update EVENTS[] in memory → renderEventsList()

Delete event
  deleteEvent(id)
  ↓ Count attendance WHERE event_id=$id
    count > 0 → showToast error, return
    count = 0 → show inline confirm
      confirm → DELETE → remove from EVENTS[] → renderEventsList()
      cancel  → renderEventsList() (confirm row gone)
```

### Attendance Tab

```
switchTab('attendance')
  ↓
selectedEventId = active event ID (from EVENTS[]) or null
loadAttendance()
  ↓ fetch attendance JOIN staff WHERE event_id=selectedEventId LIMIT 200
  ↓ ATTENDANCE[] populated
  ↓ renderAttendanceTable()
  ↓ renderAttendanceStats()

Event selector change
  selectedEventId = new selection → loadAttendance()

Search input
  attendanceSearch = e.target.value → renderAttendanceTable() (client-side filter)
```

### Late Flag Logic

```
For each record in ATTENDANCE:
  isLate(record.checked_in_at, selectedEvent.start_time)
    → selectedEvent.start_time is null → false
    → extract HH:MM from start_time
    → compare with time portion of checked_in_at (local timezone)
    → checked_in_at time > start_time → true (show "متأخر" badge)
```

---

## Attendance Stats Shape

```js
{
  total:   number,  // active staff count (STAFF.filter(s=>s.is_active).length)
  present: number,  // ATTENDANCE.length
  absent:  number,  // total - present
  rate:    number   // Math.round(present/total*100), 0 if total===0
}
```
