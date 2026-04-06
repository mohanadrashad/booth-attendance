# Quickstart: Phase 3 — Dashboard Core

**Date**: 2026-04-05  
**Branch**: `003-dashboard-core`

**Prerequisites**: Phase 1 + Phase 2 complete. `config.js` present with valid credentials.

---

## Step 1: Apply the Staff RLS Migration

Before the dashboard can write to the `staff` table, run the migration in the Supabase SQL Editor:

```sql
CREATE POLICY "anon can insert staff"
  ON staff FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update staff"
  ON staff FOR UPDATE TO anon USING (true) WITH CHECK (true);
```

**Expected**: "Success. No rows returned." for each statement.

---

## Step 2: Open the Dashboard

Open `dashboard.html` in a browser (double-click, or serve via local server).

**Expected**: Only the PIN entry screen is visible — no staff names or management controls.

---

## Step 3: Test Wrong PIN

Enter any 4-digit PIN that is **not** `1234` (e.g., `0000`) and confirm.

**Expected**: An Arabic error message appears, the PIN field clears, and the screen remains locked.

---

## Step 4: Test Correct PIN

Enter `1234` and confirm.

**Expected**: The PIN screen disappears and the staff management dashboard loads with the 5 seeded staff members shown alphabetically.

---

## Step 5: Test Session Persistence

1. After unlocking, navigate away (open a new tab or refresh the page).
2. Return to `dashboard.html`.

**Expected**: The dashboard loads directly without asking for the PIN again (session stored).

---

## Step 6: Test Real-Time Search

In the search box, type part of any Arabic name (e.g., `احمد`).

**Expected**: The staff list filters instantly to show only matching names as you type. Clear the box — all staff appear again.

---

## Step 7: Test Add Staff

1. Click "إضافة موظف".
2. Enter a new Arabic name (e.g., `موظف جديد`).
3. Click save.

**Expected**: The modal closes, the new staff member appears in the list at the correct alphabetical position. Verify in the Supabase SQL Editor:
```sql
SELECT name, is_active FROM staff ORDER BY name;
```

---

## Step 8: Test Edit Staff

1. Click the edit icon on any staff card.
2. Change the name and save.

**Expected**: The modal closes, the updated name appears immediately in the list. Verify the change in the SQL Editor.

---

## Step 9: Test Soft-Delete

1. Click the delete icon on a staff card.
2. An inline confirmation appears — click "تأكيد الحجب".

**Expected**:
- The staff member's card shows "غير نشط" in the dashboard list.
- Open `booth-attendance.html` and refresh — the deleted staff member no longer appears.
- In the SQL Editor, verify: `SELECT name, is_active FROM staff;` — the member has `is_active = false`.
- Verify attendance records are intact: `SELECT count(*) FROM attendance WHERE staff_id = '<their UUID>';`

---

## Step 10: Test Logout

Click the logout button on the dashboard.

**Expected**: The PIN screen appears. Refreshing the page also shows the PIN screen (session cleared).

---

## Step 11: Test Missing Config

1. Temporarily rename `config.js` to `config.js.bak`.
2. Refresh `dashboard.html`.

**Expected**: An Arabic error message about missing configuration — no uncaught exception.

3. Rename back to `config.js`.

---

## Common Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| PIN correct but "wrong PIN" error | Migration not applied | Run Step 1 migration in Supabase SQL Editor |
| "فشل الحفظ" on add staff | RLS migration not applied | Run Step 1 migration |
| Staff list empty after PIN | Wrong Supabase URL/key in config.js | Check config.js values |
| Dashboard shows on first load (no PIN) | sessionStorage has stale auth flag | Open DevTools → Application → sessionStorage → clear `dashboard_auth` |
| Deleted staff still on attendance page | Browser cache | Hard refresh attendance page (Ctrl+Shift+R) |
