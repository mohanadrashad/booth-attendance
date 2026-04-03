# Supabase Query Contracts: Phase 1 — Data Foundation

**Date**: 2026-04-03  
**Branch**: `001-phase1-db-setup`

This document defines the query contracts between the application pages and the Supabase data store. Each contract specifies what the page sends, what it expects back, and what errors it must handle.

---

## Contract 1: Load Active Staff

**Used by**: Attendance page (`booth-attendance.html`) on load  
**Operation**: SELECT

```
Query: staff WHERE is_active = true ORDER BY name ASC
Returns: [{ id, name, is_active }]
Errors:
  - Network unavailable → show "لا يمكن الاتصال بالخادم" error banner
  - Empty result → show "لا يوجد موظفون نشطون" message
```

**RLS gate**: anon SELECT on `staff` ✓

---

## Contract 2: Load Active Event

**Used by**: Attendance page on load  
**Operation**: SELECT

```
Query: events WHERE is_active = true LIMIT 1
Returns: { id, name, event_date } | null
Errors:
  - No active event → block check-in UI, show "لا يوجد حدث نشط" message
  - Network unavailable → same as Contract 1
```

**RLS gate**: anon SELECT on `events` ✓

---

## Contract 3: Insert Attendance Record

**Used by**: Attendance page on signature confirmation  
**Operation**: INSERT

```
Payload: { staff_id: UUID, event_id: UUID, signature_data: string | null }
Returns: { id, staff_id, event_id, checked_in_at }
Errors:
  - Duplicate (staff_id + event_id) → unique constraint violation → UI should
    have already blocked this (card is disabled), but handle gracefully
  - FK violation → staff_id or event_id no longer valid → show generic error
  - Network unavailable → show error, allow retry
```

**RLS gate**: anon INSERT on `attendance` ✓  
**Note**: `checked_in_at` and `created_at` are set by the database default (`now()`), not by the client.

---

## Contract 4: Load Settings

**Used by**: Dashboard page (`dashboard.html`) on PIN verification  
**Operation**: SELECT

```
Query: settings WHERE id = 1
Returns: { pin_hash, theme, language }
Errors:
  - No row → settings not seeded → show setup instructions
  - Network unavailable → block dashboard access
```

**RLS gate**: anon SELECT on `settings` ✓  
**Note**: `pin_hash` is a 64-character hex string. The page hashes the entered PIN client-side (Web Crypto SHA-256) and compares to this value. The plain-text PIN is never sent to or stored in the database.

---

## Contract 5: Read Attendance by Event (Phase 4 preview)

**Used by**: Dashboard attendance table (defined here for completeness)  
**Operation**: SELECT with JOIN

```
Query: attendance JOIN staff ON staff_id WHERE event_id = :eventId
Returns: [{ id, checked_in_at, staff.name, signature_data }]
Errors:
  - Empty result → show "لا توجد سجلات حضور" message
```

**RLS gate**: anon SELECT on `attendance` and `staff` ✓  
**Note**: This query is defined here to confirm the data model supports it. Implementation is Phase 4.

---

## Error Handling Standard

All query errors must follow this pattern in the UI:

1. Log the raw error to `console.error` for debugging
2. Show a user-facing Arabic error message (no technical details)
3. Do not leave the UI in a broken/blank state — always show a fallback message
