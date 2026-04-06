# Quickstart: Phase 4 — Events & Attendance Overview

**Date**: 2026-04-05  
**Branch**: `004-events-attendance`

**Prerequisites**: Phases 1–3 complete. `config.js` present. Phase 3 RLS migration applied.

---

## Step 1: Apply Migrations

Run both migrations in the Supabase SQL Editor:

**Migration 002 — Add start_time to events:**
```sql
ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT NULL;
```

**Migration 003 — Events RLS for dashboard writes:**
```sql
CREATE POLICY "anon can insert events"
  ON events FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update events"
  ON events FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can delete events"
  ON events FOR DELETE TO anon USING (true);
```

**Expected**: "Success. No rows returned." for each statement.

---

## Step 2: Verify Tab Navigation

Open `dashboard.html`, enter PIN `1234`. Verify three tabs are visible: "الموظفون", "الفعاليات", "الحضور". Click each — the correct section shows and others hide.

---

## Step 3: Test Create Event

1. Click the "الفعاليات" tab.
2. Click "إنشاء فعالية".
3. Enter name: "يوم التوظيف 2026", date: today, start time: `09:00`.
4. Save.

**Expected**: Modal closes, new event appears in the events list.

---

## Step 4: Test Activate Event

1. Click "تفعيل" on the new event.

**Expected**: The new event shows as active (green badge). The previous active event ("معرض الكتاب 2026") becomes inactive.

2. Open `booth-attendance.html` and refresh.

**Expected**: Header shows "يوم التوظيف 2026".

---

## Step 5: Test Event Switch Resets Attendance State

1. Check in one staff member on `booth-attendance.html` under the new event.
2. Switch back to "معرض الكتاب 2026" as the active event in the dashboard.
3. Refresh `booth-attendance.html`.

**Expected**: No staff shown as checked in (the previous event's check-ins don't appear for the new active event).

---

## Step 6: Test Attendance Table

1. Click the "الحضور" tab in the dashboard.

**Expected**: The attendance table shows records for the currently active event. Columns: staff name, check-in time.

2. Use the event selector to switch to another event.

**Expected**: Table updates to show that event's records (or empty state if none).

---

## Step 7: Test Late Arrival Flag

1. Ensure "يوم التوظيف 2026" is active with start_time `09:00`.
2. On `booth-attendance.html`, check in a staff member (this will record the current time).
3. Open the Attendance tab in the dashboard.

**Expected**: If you checked in after 09:00, the row shows a "متأخر" badge. If before 09:00, no badge.

To force a late record for testing, run in the Supabase SQL Editor:
```sql
UPDATE attendance
SET checked_in_at = now() - INTERVAL '1 day' + INTERVAL '10 hours 30 minutes'
WHERE id = (SELECT id FROM attendance ORDER BY created_at DESC LIMIT 1);
```
Then update the event to `start_time = '09:00'`. The row should show "متأخر".

---

## Step 8: Test Attendance Stats

1. With 5 active staff and some checked in, view the "الحضور" tab.

**Expected**: Stats bar shows correct total / present / absent / percentage.

2. Check in one more staff member on the attendance page, then refresh the Attendance tab.

**Expected**: Present count and percentage update.

---

## Step 9: Test Delete Event Guard

1. Try to delete "معرض الكتاب 2026" (which has check-ins from Phase 2 testing).

**Expected**: Error toast — "لا يمكن حذف فعالية لها سجلات حضور". Event is not deleted.

2. Create a new empty test event, then try to delete it.

**Expected**: Inline confirmation appears. Confirm — event is removed from the list.

---

## Step 10: Test Edit Event

1. Click the edit icon on any event.
2. Change the name and save.

**Expected**: Updated name reflects immediately in the events list.

---

## Common Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "فشل الحفظ" on create/edit event | Migration 003 not applied | Run Step 1 migrations |
| `start_time` field missing from form | Migration 002 not applied | Run Step 1 migrations |
| Attendance table shows wrong event | `selectedEventId` state stale | Switch event in selector dropdown |
| No late badges even after 09:00 | `start_time` not saved on event | Edit event and re-enter start_time |
| Stats show wrong total | Soft-deleted staff included | Check `is_active` filter in STAFF computation |
