# Data Model: Phase 2 — Attendance Page (DB Connected)

**Date**: 2026-04-05  
**Branch**: `002-attendance-page-db`

> **Note**: The database schema is already defined in Phase 1 (`specs/001-phase1-db-setup/data-model.md`). This document describes the **JavaScript in-memory state model** — how data is shaped once loaded from the database and held in the page for rendering.

---

## Module-Level State Variables

These replace the Phase 1 (hardcoded) variables in `booth-attendance.html`:

### `STAFF` (array) — replaces hardcoded `const STAFF = [...]`

```
Type:    Array<StaffRecord>
Source:  Loaded from DB on init (staff table, is_active = true, ordered by name)
Mutated: Never after init (staff list is read-only during a session)
```

**StaffRecord shape**:

| Field | Type   | Source         | Description                          |
|-------|--------|----------------|--------------------------------------|
| `id`  | string | DB (UUID)      | Primary key — used as attendance key |
| `name`| string | DB (TEXT)      | Display name shown on card           |

---

### `currentEvent` (object or null) — new variable

```
Type:    EventRecord | null
Source:  Loaded from DB on init (events table, is_active = true, LIMIT 1)
Mutated: Never during session (event switching is Phase 4)
```

**EventRecord shape**:

| Field        | Type   | Source    | Description                             |
|--------------|--------|-----------|-----------------------------------------|
| `id`         | string | DB (UUID) | Used as `event_id` on attendance insert |
| `name`       | string | DB (TEXT) | Shown in page header                    |
| `event_date` | string | DB (DATE) | Shown in page header (ISO date string)  |

**Null state**: When `currentEvent === null`, check-in functionality is disabled and an explanatory message is shown.

---

### `attendance` (object) — replaces in-memory `let attendance = {}`

```
Type:    Record<staffId: string, AttendanceRecord>
Source:  Loaded from DB on init (attendance table, event_id = currentEvent.id)
         Appended on each successful check-in confirmation
Mutated: Append-only during session (no edits or deletes in this phase)
```

**AttendanceRecord shape**:

| Field       | Type   | Source               | Description                                 |
|-------------|--------|----------------------|---------------------------------------------|
| `time`      | string | Derived from DB      | Formatted Arabic time string for card display |
| `signature` | string | Canvas + DB          | Base64 PNG data URL stored in DB            |
| `timestamp` | string | DB (`checked_in_at`) | ISO timestamp from server (authoritative)   |
| `recordId`  | string | DB (UUID)            | Attendance row ID (for future reference)    |

**Key**: `staffId` (UUID string) — same type as `StaffRecord.id`.

---

## State Transitions

### On page load (`init()`)

```
DB queries (parallel):
  staff WHERE is_active = true → STAFF[]
  events WHERE is_active = true LIMIT 1 → currentEvent | null

If currentEvent != null:
  attendance WHERE event_id = currentEvent.id → attendance{}

→ renderStaff()
→ updateStats()
```

### On check-in confirm (`confirmAttendance()`)

```
Input: currentStaffId (UUID), currentEvent.id (UUID), canvas signature (base64)

DB insert: attendance { staff_id, event_id, signature_data }
  ↓ success
attendance[currentStaffId] = { time, signature, timestamp, recordId }
  ↓
renderStaff() — card shows checked-in state
updateStats() — present count increments
showToast(success)

  ↓ error
showToast(failure) — no state change
```

### Card render state (per staff member)

```
attendance[staff.id] exists?
  YES → card class: "staff-card present", pointer-events: none
        shows: time, signature preview, "حاضر" badge
  NO  → card class: "staff-card", onclick: openModal(staff.id)
        shows: "لم يسجل بعد", "غائب" badge
```

---

## Loading & Error States

| State          | Trigger                              | UI Effect                                      |
|----------------|--------------------------------------|------------------------------------------------|
| Loading        | `init()` starts                      | `#loadingOverlay` shown, `#staffList` hidden   |
| Loaded         | All queries resolve successfully     | `#loadingOverlay` hidden, staff grid shown     |
| No active event | `currentEvent === null`             | Staff grid shows, all cards non-interactive, message displayed |
| Network error  | Query rejects or returns error       | Error banner shown with Arabic message         |
| Config missing | `SUPABASE_URL` undefined             | Fatal error shown before any query is made     |
| Save error     | `attendance` insert fails            | Error toast shown, card remains clickable      |

---

## Function Signature Changes Summary

| Function           | Before (Phase 1)     | After (Phase 2)                             |
|--------------------|----------------------|---------------------------------------------|
| `init()`           | Synchronous          | `async`, fetches DB data                    |
| `confirmAttendance()` | Synchronous       | `async`, writes to DB                       |
| `renderStaff()`    | Reads `STAFF` const  | Reads `STAFF` variable (same structure, different source) |
| `updateStats()`    | Reads `STAFF.length` | Reads `STAFF.length` (unchanged)            |
| `exportData()`     | Reads `attendance{}` | Reads `attendance{}` (same, now DB-hydrated) |
| `openModal(id)`    | Reads `STAFF` array  | Reads `STAFF` array (unchanged)             |
