# Quickstart: Phase 2 — Attendance Page (DB Connected)

**Date**: 2026-04-05  
**Branch**: `002-attendance-page-db`

This guide walks you through verifying Phase 2 is working correctly.

**Prerequisites**: Phase 1 complete — Supabase project created, `schema.sql` and `seed.sql` run, `config.js` present with valid credentials.

---

## Step 1: Open the Attendance Page

Open `booth-attendance.html` in a browser (double-click the file, or serve via a local server).

**Expected**: A brief loading state, then the staff grid appears with the 5 seeded Arabic names. The event name "معرض الكتاب 2026" (or your active event) appears in the header.

**If you see a blank or broken grid**: Check the browser console for errors. Most likely `config.js` is missing or has incorrect values.

---

## Step 2: Verify Staff Loads from Database

1. Open the Supabase SQL Editor and run:
   ```sql
   INSERT INTO staff (name) VALUES ('موظف اختبار');
   ```
2. Refresh the attendance page.
3. **Expected**: The new staff member "موظف اختبار" appears in the grid.
4. Clean up: In the SQL Editor, run `DELETE FROM staff WHERE name = 'موظف اختبار';`

---

## Step 3: Verify Active Event Displays

1. In the Supabase SQL Editor, run:
   ```sql
   SELECT name, event_date FROM events WHERE is_active = true;
   ```
2. **Expected**: The name and date shown in the page header match this query result.

---

## Step 4: Test a Check-In and Verify Persistence

1. Click any staff card on the attendance page.
2. Draw a signature in the modal.
3. Click "تأكيد الحضور".
4. **Expected**: The card shows the checked-in state with the time and signature preview. A success toast appears.
5. **Refresh the page** (F5 or Ctrl+R).
6. **Expected**: The same card still shows checked-in state — the check-in was saved to the database and reloads on refresh. This is the key difference from Phase 1 (which reset on refresh).

---

## Step 5: Verify the Check-In Record in the Database

In the Supabase SQL Editor:
```sql
SELECT s.name, a.checked_in_at, length(a.signature_data) AS sig_size
FROM attendance a
JOIN staff s ON s.id = a.staff_id
ORDER BY a.checked_in_at DESC
LIMIT 5;
```

**Expected**: Your check-in appears with the staff name, a recent timestamp, and a non-zero signature size.

---

## Step 6: Test the No-Active-Event State

1. In the Supabase SQL Editor, deactivate the active event:
   ```sql
   UPDATE events SET is_active = false WHERE is_active = true;
   ```
2. Refresh the attendance page.
3. **Expected**: The staff grid is visible but all cards are non-interactive. A message explains no active event is set.
4. Restore: In the SQL Editor, re-activate the event:
   ```sql
   UPDATE events SET is_active = true WHERE name = 'معرض الكتاب 2026';
   ```

---

## Step 7: Test the Export After Refresh

1. Record 2–3 check-ins.
2. Refresh the page (to confirm they reload from DB).
3. Click the export button from the menu.
4. **Expected**: The exported report includes all check-ins, including those recorded before the refresh.

---

## Step 8: Test Error Handling

1. Temporarily rename `config.js` to `config.js.bak`.
2. Refresh the attendance page.
3. **Expected**: An Arabic error message about missing configuration — no uncaught exception in console.
4. Rename `config.js.bak` back to `config.js`.

---

## Common Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Blank staff grid, no error | `config.js` missing or not loaded | Check file exists and is in the same directory as the HTML |
| "supabase is not defined" in console | CDN script not loading | Check internet connection; verify the CDN `<script>` tag is in `<head>` |
| Staff grid loads but shows old hardcoded names | Old cached HTML | Hard-refresh (Ctrl+Shift+R) |
| Check-in saves but disappears on refresh | Wrong `event_id` used on insert | Verify `currentEvent.id` matches the active event UUID in the DB |
| Duplicate check-in error in console | Normal — expected | The UNIQUE constraint blocks it; UI should already prevent this via non-interactive card |
