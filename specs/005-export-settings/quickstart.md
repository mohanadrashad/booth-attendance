# Quickstart: Phase 5 — Export & Settings

**Date**: 2026-04-05  
**Branch**: `005-export-settings`

**Prerequisites**: Phases 1–4 complete. `config.js` present. Phase 4 migrations applied (`start_time` column + events RLS).

---

## Step 1: Apply Migration

Run in the Supabase SQL Editor:

**Migration 004 — Settings RLS for PIN change:**
```sql
CREATE POLICY "anon can update settings"
  ON settings FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
```

**Expected**: "Success. No rows returned."

---

## Step 2: Verify Tab Bar

Open `dashboard.html`, enter PIN `1234`. Verify **five** tabs are visible:
- الموظفون
- الفعاليات
- الحضور
- تصدير
- الإعدادات

Click each tab — correct section shows and others hide.

---

## Step 3: Test Export Preview

1. Click the "تصدير" tab.

**Expected**: An event selector dropdown appears, populated with all events. The active event is pre-selected (labelled with ●). A preview line shows "سيتم تصدير N سجل" with the correct count.

2. Use the event selector to switch to an event with no attendance records.

**Expected**: Preview shows "سيتم تصدير 0 سجل". All three export buttons are disabled.

---

## Step 4: Test CSV Export

1. Select "معرض الكتاب 2026" (which has check-ins from earlier phases).
2. Click "تصدير CSV".

**Expected**: A file named `معرض-الكتاب-2026-attendance.csv` downloads.

3. Open the file in a text editor or Excel.

**Expected**: First row is headers (`الاسم,وقت الحضور`). Each subsequent row is one attendee with their name and check-in time. Arabic text displays correctly (UTF-8 BOM ensures Excel compatibility).

---

## Step 5: Test Text Export

1. With the same event selected, click "تصدير نصي".

**Expected**: On mobile: native share sheet opens. On desktop: clipboard copy with toast "تم نسخ التقرير ✓".

2. Paste into a text editor or messaging app.

**Expected**: Multi-line Arabic report with event name, date, total count, and numbered attendee list.

---

## Step 6: Test PDF Export

1. With the same event selected, click "تصدير PDF".

**Expected**: A new browser tab/window opens showing a formatted table. The browser print dialog appears automatically. The table shows: #, الاسم, وقت الحضور, التوقيع (with signature images visible for staff who signed in).

2. Click "Save as PDF" in the print dialog.

**Expected**: A PDF file downloads containing the formatted report with signatures.

3. Switch to an event where staff were checked in without signatures (if any).

**Expected**: PDF renders with blank signature cells for those rows — no errors.

---

## Step 7: Test Zero-Record Guard

1. Create a new test event with no attendance records.
2. Select it in the export selector.
3. Click any export button.

**Expected**: All export buttons are disabled (grayed out). No file downloads. Toast shows "❌ لا توجد سجلات للتصدير" if buttons are somehow triggered.

---

## Step 8: Test PIN Change

1. Click the "الإعدادات" tab.
2. In the PIN Change section:
   - Current PIN: `1234`
   - New PIN: `5678`
   - Confirm PIN: `5678`
3. Click "حفظ".

**Expected**: Success toast "تم تغيير رمز PIN بنجاح ✓". Form clears.

4. Click "خروج". Try logging in with `1234`.

**Expected**: "رمز PIN غير صحيح" error.

5. Log in with `5678`.

**Expected**: Dashboard unlocks successfully.

6. Change PIN back to `1234` for convenience (repeat steps 1–3 with pins reversed).

---

## Step 9: Test PIN Change Validation

1. Try submitting with wrong current PIN.

**Expected**: "رمز PIN الحالي غير صحيح" shown inline. No DB update.

2. Try submitting with mismatched new/confirm PINs.

**Expected**: "رمزا PIN غير متطابقَين" shown inline.

3. Try typing only 3 digits in the New PIN field.

**Expected**: Save button remains disabled.

---

## Step 10: Test Theme Toggle

1. In the Settings tab, find the theme toggle switch.
2. Toggle from dark to light.

**Expected**: Dashboard switches to a light color scheme immediately. Toggle label updates to reflect current state.

3. Refresh the page (stay logged out if needed, then log back in).

**Expected**: Light theme is still active — preference was remembered.

4. Toggle back to dark.

**Expected**: Dark mode restores. Refresh confirms it persists.

---

## Common Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "فشل الحفظ" on PIN change | Migration 004 not applied | Run Step 1 migration |
| Export buttons always disabled | `exportRecordCount` not updating | Check `updateExportPreview()` call in `loadExport()` |
| PDF opens blank / no print dialog | Popup blocker active | Allow popups from this page |
| Arabic CSV shows garbled in Excel | UTF-8 BOM missing | Verify `'\uFEFF'` prepended to CSV string |
| Signatures missing from PDF | `signature_data` null in DB | Normal — staff checked in without signing (blank cell expected) |
| Theme resets on refresh | localStorage not being written | Check `toggleTheme()` localStorage.setItem call |
| Light theme flashes dark on load | Early-apply IIFE missing or misplaced | Verify IIFE is at top of `<head>` before `<style>` |
