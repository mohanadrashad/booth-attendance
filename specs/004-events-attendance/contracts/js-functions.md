# JavaScript Function Contracts: Phase 4 — Events & Attendance Overview

**Date**: 2026-04-05  
**File**: `dashboard.html` (extensions to existing file)

---

## Tab Navigation

### `switchTab(tab: 'staff'|'events'|'attendance')`
```
Effect: Hides all .tab-section divs, shows #section-{tab}
        Updates .tab-btn active class
        Calls loadEvents() if tab==='events'
        Calls loadAttendance() if tab==='attendance'
```

---

## Events Section (US1, US2)

### `async loadEvents()`
```
Steps:
  1. Show loading state in #eventsList
  2. SELECT id, name, event_date, is_active, start_time FROM events ORDER BY event_date DESC
  3. EVENTS = result.data
  4. renderEventsList()
```

### `renderEventsList()`
```
Inputs:  Reads EVENTS[] global
Effect:  Re-renders #eventsList
         Each card: name, date, active badge, Edit + Activate + Delete buttons
         Active event card: "Activate" button disabled/hidden
         Inline delete confirm row when deleteConfirmEventId matches
Pure render — no DB calls
```

### `openEventModal(mode: 'add'|'edit', event?)`
```
Effect: Sets eventModalMode, editEventId
        Pre-fills #eventNameInput, #eventDateInput, #eventStartTimeInput
        Shows #eventModal
```

### `closeEventModal()`
```
Effect: Hides #eventModal, resets modal state variables and inputs
```

### `async submitEventModal()`
```
Steps:
  1. Validate name not empty, date not empty → show #eventModalError if invalid
  2. Disable save button
  3. If 'add': INSERT {name, event_date, start_time} RETURNING *
              push to EVENTS[], sort by event_date DESC, closeEventModal(), renderEventsList()
  4. If 'edit': UPDATE SET name, event_date, start_time WHERE id=editEventId RETURNING *
               update EVENTS[] entry, closeEventModal(), renderEventsList()
  5. On error: show #eventModalError, re-enable button
```

### `async activateEvent(eventId: string)`
```
Steps:
  1. UPDATE events SET is_active=false WHERE is_active=true
  2. UPDATE events SET is_active=true WHERE id=eventId
  3. Update EVENTS[] in memory: set all is_active=false, set target is_active=true
  4. renderEventsList()
  5. showToast('تم تفعيل الفعالية ✓')
```

### `async deleteEvent(eventId: string)`
```
Steps:
  1. COUNT attendance WHERE event_id=eventId (head:true)
  2. count > 0 → showToast('❌ لا يمكن حذف فعالية لها سجلات حضور', error=true), return
  3. count = 0 → deleteConfirmEventId = eventId → renderEventsList()

Called on confirm button:
  4. DELETE FROM events WHERE id=eventId
  5. Remove from EVENTS[]
  6. deleteConfirmEventId = null → renderEventsList()
  7. showToast('تم حذف الفعالية ✓')
```

---

## Attendance Section (US3, US4, US5)

### `async loadAttendance()`
```
Steps:
  1. selectedEventId = selectedEventId ?? active event ID from EVENTS[]
  2. Show loading state in #attendanceTable
  3. Fetch attendance with JOIN: .select('id, checked_in_at, staff:staff_id(name)')
                                 .eq('event_id', selectedEventId)
                                 .order('checked_in_at').limit(200)
  4. ATTENDANCE = result.data
  5. renderAttendanceTable()
  6. renderAttendanceStats()
```

### `renderAttendanceTable()`
```
Inputs:  Reads ATTENDANCE[], attendanceSearch, EVENTS[] (for start_time lookup)
Effect:  Filters ATTENDANCE by attendanceSearch (staff.name.includes)
         Renders table rows: staff name, formatted check-in time, late badge if isLate()
         Shows empty state if no records or no results after filter
         Shows note if records were capped at 200
Pure render — no DB calls
```

### `renderAttendanceStats()`
```
Inputs:  Reads STAFF[], ATTENDANCE[]
Effect:  Computes { total, present, absent, rate } → updates stats display in #attendanceStats
         Handles total===0 case (shows 0% not NaN)
Pure render — no DB calls
```

### `isLate(checkedInAt: string, startTime: string|null) → boolean`
```
Inputs:  checkedInAt — ISO timestamp string
         startTime — 'HH:MM:SS' or null
Returns: false if startTime is null
         true if local time of checkedInAt is strictly after startTime
Pure function — no side effects
```

### (inline event listener on #eventSelector)
```
Event:  'change'
Steps:
  1. selectedEventId = e.target.value
  2. loadAttendance()
```

### (inline event listener on #attendanceSearchInput)
```
Event:  'input'
Steps:
  1. attendanceSearch = e.target.value.trim()
  2. renderAttendanceTable()
```
