# JavaScript Function Contracts: Phase 5 — Export & Settings

**Date**: 2026-04-05  
**File**: `dashboard.html` (extensions to existing file)

---

## Tab Navigation Extension

### `switchTab(tab)` — extended
```
Existing function. Add support for:
  tab = 'export'     → shows #section-export, calls loadExport()
  tab = 'settings'   → shows #section-settings, calls loadSettings()
No other changes to switchTab().
```

Tab bar gains two new buttons:
```html
<button class="tab-btn" data-tab="export"   onclick="switchTab('export')">تصدير</button>
<button class="tab-btn" data-tab="settings" onclick="switchTab('settings')">الإعدادات</button>
```

---

## Export Section (US1)

### `loadExport()`
```
Steps:
  1. If EVENTS[] is empty:
       show "لا توجد فعاليات" in #section-export, return
  2. exportSelectedEventId = exportSelectedEventId
       ?? active event ID from EVENTS[]
       ?? EVENTS[0].id
  3. Populate #exportEventSelector <option> elements from EVENTS[]
       (active event labelled with ●; selected = exportSelectedEventId)
  4. Wire #exportEventSelector 'change' → exportSelectedEventId = e.target.value; updateExportPreview()
  5. updateExportPreview()
```

### `async updateExportPreview()`
```
Steps:
  1. Count attendance records for exportSelectedEventId:
       SELECT id FROM attendance WHERE event_id=exportSelectedEventId (head:true, count:'exact')
  2. exportRecordCount = count
  3. Render count into #exportPreview: "سيتم تصدير N سجل"
  4. If count === 0: disable all three export buttons
     Else: enable all three export buttons
```

### `async exportCSV()`
```
Steps:
  1. If exportRecordCount === 0: showToast('❌ لا توجد سجلات للتصدير', true); return
  2. Fetch: SELECT checked_in_at, staff:staff_id(name) FROM attendance
            WHERE event_id=exportSelectedEventId ORDER BY checked_in_at
  3. Find event: EVENTS.find(e => e.id === exportSelectedEventId)
  4. Build CSV string:
       BOM + header row (الاسم, وقت الحضور) + one row per record
       Time formatted as HH:MM (local)
       All values wrapped in double-quotes
  5. Trigger download:
       Blob(csv, {type:'text/csv;charset=utf-8'})
       URL.createObjectURL → <a>.click() → URL.revokeObjectURL
  6. Filename: `${safeFilename(event.name)}-attendance.csv`
```

### `async exportText()`
```
Steps:
  1. If exportRecordCount === 0: showToast('❌ لا توجد سجلات للتصدير', true); return
  2. Fetch same records as exportCSV
  3. Build Arabic text report:
       Line 1: "تقرير الحضور — [event.name]"
       Line 2: "التاريخ: [dd/mm/yyyy]"
       Line 3: "إجمالي الحضور: [N] موظف"
       Separator line
       Numbered list: "1. [staff name] — [HH:MM]"
  4. Try navigator.share({text, title}) — fallback to navigator.clipboard.writeText(text)
  5. showToast('تم نسخ التقرير ✓') on clipboard success
     showToast('❌ فشل المشاركة', true) on error
```

### `async exportPDF()`
```
Steps:
  1. If exportRecordCount === 0: showToast('❌ لا توجد سجلات للتصدير', true); return
  2. Fetch: SELECT checked_in_at, signature_data, staff:staff_id(name) FROM attendance
            WHERE event_id=exportSelectedEventId ORDER BY checked_in_at
  3. Find event from EVENTS[]
  4. Build print HTML string:
       <!DOCTYPE html><html dir="rtl" lang="ar">
       <head>
         <meta charset="UTF-8">
         <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;700&display=swap" rel="stylesheet">
         <style>
           body { font-family: 'Tajawal', sans-serif; padding: 20px; }
           h1   { font-size: 18px; margin-bottom: 4px; }
           p    { font-size: 13px; color: #666; margin-bottom: 16px; }
           table { width: 100%; border-collapse: collapse; }
           th, td { border: 1px solid #ddd; padding: 8px; text-align: right; }
           th { background: #f5f5f5; font-size: 12px; }
           img.sig { max-height: 40px; max-width: 80px; }
           @media print { body { padding: 0; } }
         </style>
       </head>
       <body>
         <h1>تقرير الحضور — [event.name]</h1>
         <p>التاريخ: [dd/mm/yyyy] · الإجمالي: [N] موظف</p>
         <table>
           <thead><tr><th>#</th><th>الاسم</th><th>وقت الحضور</th><th>التوقيع</th></tr></thead>
           <tbody>
             [rows: <td>N</td><td>name</td><td>HH:MM</td>
                    <td><img class="sig" src="[signature_data || '']"></td>]
           </tbody>
         </table>
       </body></html>
  5. const w = window.open('', '_blank')
     w.document.write(html); w.document.close()
     w.onload = () => { w.focus(); w.print(); }
```

### `safeFilename(eventName: string) → string`
```
Returns: eventName with spaces replaced by '-', non-word non-Arabic chars stripped.
         Falls back to 'attendance' if result is empty.
Pure function — no side effects.
```

---

## Settings Section (US2, US3)

### `loadSettings()`
```
Steps:
  1. Apply current theme state to #themeToggle checked state
     (read from document.documentElement.classList.contains('light-theme'))
  2. Clear PIN change form inputs
  3. Hide PIN change error
No DB fetch needed.
```

### `async submitPinChange()`
```
Steps:
  1. Read currentPin, newPin, confirmPin from inputs
  2. Validate newPin: must be exactly 4 digits → show #pinChangeError if not
  3. Validate confirmPin === newPin → show #pinChangeError if not
  4. Disable save button
  5. const currentHash = await hashPin(currentPin)  // reuses existing hashPin()
  6. Fetch { pin_hash } from settings WHERE id=1
  7. If currentHash !== data.pin_hash:
       show #pinChangeError "رمز PIN الحالي غير صحيح"; re-enable button; return
  8. const newHash = await hashPin(newPin)
  9. UPDATE settings SET pin_hash = newHash WHERE id = 1
  10. On success: showToast('تم تغيير رمز PIN بنجاح ✓'); clearPinChangeForm()
  11. On error: show #pinChangeError "فشل الحفظ، حاول مرة أخرى"; re-enable button
```

### `clearPinChangeForm()`
```
Effect: Clears all three PIN inputs, hides #pinChangeError, re-enables save button.
Pure DOM operation.
```

### `toggleTheme()`
```
Steps:
  1. const isLight = document.documentElement.classList.toggle('light-theme')
  2. localStorage.setItem('booth_theme', isLight ? 'light' : 'dark')
No DB call needed.
```

### (IIFE — early theme apply)
```
Location: <script> tag at the very top of <head>, before <style> block
Effect:   Reads localStorage.getItem('booth_theme')
          If 'light': document.documentElement.classList.add('light-theme')
Purpose:  Prevents flash of dark theme when user has light preference
```

### (inline event listener on #pinNewInput)
```
Event:  'input'
Effect: Disable save button if value.length !== 4
```
