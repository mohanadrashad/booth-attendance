# JavaScript Function Contracts: Phase 2 — Attendance Page (DB Connected)

**Date**: 2026-04-05  
**Branch**: `002-attendance-page-db`

This document defines the behavioural contracts for each modified or new JavaScript function in `booth-attendance.html`. Unchanged functions are omitted.

---

## New: Supabase Client Initialization

**Location**: Top of `<script>` block, before any function definitions.

```
Precondition:  SUPABASE_URL and SUPABASE_ANON_KEY globals exist (from config.js)
               Supabase CDN script has loaded (from <head>)
Postcondition: _supabase is a live Supabase client instance
Error:         If globals missing → call showFatalError() and return early
```

---

## Modified: `init()` → now `async init()`

**Purpose**: Entry point. Fetches all required data from DB in parallel, renders UI.

```
Inputs:    None
Outputs:   Populates STAFF[], currentEvent, attendance{} globals

Steps:
  1. Guard: check SUPABASE_URL and SUPABASE_ANON_KEY defined → showFatalError if not
  2. showLoading(true)
  3. Parallel fetch: STAFF from staff table + currentEvent from events table
  4. If staff query errors → showError(), return
  5. If event query returns null → set currentEvent = null, disable check-ins
  6. If currentEvent exists → fetch attendance for currentEvent.id
  7. Hydrate attendance{} from DB records
  8. Set date display in header (from currentEvent.event_date if available, else today)
  9. renderStaff()
  10. updateStats()
  11. initCanvas()
  12. showLoading(false)

Error handling:
  - Any DB error → showError('حدث خطأ أثناء التحميل') displayed in staff area
  - Missing config → showFatalError('ملف الإعدادات مفقود')
```

---

## Modified: `confirmAttendance()` → now `async confirmAttendance()`

**Purpose**: Saves a confirmed check-in to the database, then updates UI.

```
Preconditions:
  - currentStaffId is set (not null)
  - hasDrawn is true (signature drawn)
  - currentEvent is not null

Inputs:    None (reads currentStaffId, currentEvent, canvas state from globals)
Outputs:   Appends to attendance{}, re-renders staff grid and stats

Steps:
  1. Guard: return if !currentStaffId || !hasDrawn || !currentEvent
  2. Capture sigData = canvas.toDataURL('image/png')
  3. Disable confirm button (prevent double-submit)
  4. Insert into attendance: { staff_id: currentStaffId, event_id: currentEvent.id, signature_data: sigData }
  5. Select back: id, checked_in_at (server timestamp)
  6. On error:
     - Re-enable confirm button
     - showToast('❌ فشل تسجيل الحضور، حاول مرة أخرى')
     - Return (do NOT update attendance cache)
  7. On success:
     - Parse checked_in_at → formatted Arabic time string
     - attendance[currentStaffId] = { time, signature: sigData, timestamp, recordId }
     - closeModal()
     - renderStaff()
     - updateStats()
     - showToast('✓ تم تسجيل حضور [name]')

Postcondition (success):
  - attendance[currentStaffId] exists in memory
  - DB has the attendance record
  - Staff card shows checked-in state

Postcondition (error):
  - attendance[currentStaffId] does NOT exist
  - DB has no record (insert failed)
  - Staff card remains clickable
```

---

## New: `showLoading(visible: boolean)`

**Purpose**: Toggles the loading overlay during init.

```
Inputs:  visible — true to show loading, false to hide
Outputs: Toggles CSS classes on #loadingOverlay and #staffList
```

---

## New: `showError(message: string)`

**Purpose**: Displays a recoverable error message in the staff area (e.g. network failure on load).

```
Inputs:  message — Arabic error string
Outputs: Renders error message into #staffList area (replaces grid content)
```

---

## New: `showFatalError(message: string)`

**Purpose**: Displays a non-recoverable error (e.g. missing config.js) and blocks all further interaction.

```
Inputs:  message — Arabic error string
Outputs: Replaces page content with error message; no further functions execute
```

---

## Unchanged Functions (behaviour preserved)

| Function         | Status    | Notes                                                    |
|------------------|-----------|----------------------------------------------------------|
| `renderStaff()`  | Unchanged | Now reads from `STAFF[]` (UUID-keyed) instead of const  |
| `updateStats()`  | Unchanged | Still reads `STAFF.length` and `Object.keys(attendance)` |
| `openModal(id)`  | Unchanged | Now receives UUID string instead of integer              |
| `closeModal()`   | Unchanged | No changes                                               |
| `exportData()`   | Minor     | Uses `currentEvent.name` in report title instead of hardcoded string |
| `resetAll()`     | Scoped    | Clears only in-memory `attendance{}`; does NOT delete DB records |
| `showToast()`    | Unchanged | No changes                                               |
| `initCanvas()`   | Unchanged | No changes                                               |
| `clearSignature()` | Unchanged | No changes                                             |
| `getInitials()`  | Unchanged | No changes                                               |
