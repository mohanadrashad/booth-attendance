# Research: Phase 5 — Export & Settings

**Date**: 2026-04-05  
**Branch**: `005-export-settings`

---

## Section 1: PDF Export Strategy

### Decision: `window.print()` with a dynamically generated print window

**Rationale**: The app is a single HTML file with no build system. Generating a new browser window containing print-optimized HTML — then calling `window.print()` on it — requires zero external libraries, handles Arabic RTL text natively (the browser's rendering engine handles it perfectly), and embeds base64 signature images without any encoding gymnastics.

**Alternatives considered**:
- **jsPDF (CDN)**: Lacks native RTL/Arabic text support. Workarounds require loading custom Arabic fonts and a separate arabicReshaper module — significant complexity and fragile CDN loading.
- **pdfmake-rtl (CDN)**: A fork of pdfmake with RTL support. Works but adds two CDN script tags and a dependency on an npm-published fork that may not be maintained long-term. The `unpkg.com/pdfmake-rtl` CDN is available but not as battle-tested as major libraries.
- **html2canvas + jsPDF**: Renders HTML to canvas then to PDF. Heavy, slow for tables, produces rasterised (not vector/text-selectable) output.

**Chosen implementation**:
```
exportPDF(eventId):
  1. Fetch attendance records with staff name + signature_data
  2. Build an HTML string: full page with <html dir="rtl">, Tajawal font link,
     a print-specific CSS (page margins, table styles, signature img cells)
  3. Open a new window: const w = window.open('', '_blank')
  4. Write the HTML into it: w.document.write(html); w.document.close()
  5. Wait for fonts/images to load: w.onload = () => w.print()
  6. (Optional) close window after print dialog: w.onafterprint = () => w.close()
```

**Gotchas**:
- `signature_data` in the DB is stored as a full data URI (`data:image/png;base64,...`). Use directly as the `src` of `<img>` in the print HTML — no transformation needed.
- If `signature_data` is null, render an empty `<td>` with a light border (blank signature cell).
- Some browsers block `window.open()` if not triggered by a direct user interaction (click). The PDF export button click IS a user interaction, so this is safe.
- The print dialog is native to the browser — the user selects "Save as PDF" themselves. This is the same workflow used by virtually every web-based invoice/report generator.

---

## Section 2: CSV Export

### Decision: Pure JS Blob + anchor click, UTF-8 BOM for Excel Arabic compatibility

**Rationale**: No library needed. Building a CSV string from an array of records, wrapping it in a `Blob` with `text/csv;charset=utf-8`, creating an object URL, and clicking a hidden `<a>` tag is standard practice and works in all modern browsers.

**Implementation**:
```javascript
function downloadCSV(filename, rows) {
  const BOM = '\uFEFF'; // UTF-8 BOM — makes Excel open Arabic correctly
  const lines = rows.map(r => [r.name, r.time].map(v => `"${v}"`).join(','));
  const csv = BOM + 'الاسم,وقت الحضور\n' + lines.join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename; a.click();
  URL.revokeObjectURL(url);
}
```

**Gotchas**:
- Without the UTF-8 BOM (`\uFEFF`), Microsoft Excel opens Arabic CSV as garbled characters (mojibake). Always prepend it.
- Wrap all field values in double-quotes to handle commas in names.
- File name should sanitise the event name (replace spaces with hyphens, remove special chars) to ensure a valid filename across OSes.

---

## Section 3: Text Export

### Decision: Reuse existing Web Share API + clipboard fallback pattern from `booth-attendance.html`

**Rationale**: Phase 2 already implemented this pattern. Reuse it identically. The `navigator.share()` API opens the native share sheet on mobile; on desktop it falls back to `navigator.clipboard.writeText()` with a toast confirmation.

**Implementation**: Build a multi-line Arabic string:
```
تقرير الحضور — [اسم الفعالية]
التاريخ: [dd/mm/yyyy]
إجمالي الحضور: [N]
─────────────────
1. أحمد العتيبي — 09:05
2. سارة الحربي — 09:12
...
```

---

## Section 4: Theme Toggle

### Decision: `localStorage` + `.light-theme` class on `<html>`, CSS variable overrides

**Rationale**: The spec explicitly states theme preference is per-device (not DB-synced). `localStorage` is the correct tool. Applying a class to `<html>` (rather than `<body>`) means the CSS variable overrides apply before any layout is painted, preventing a flash of the wrong theme.

**Implementation**:
```javascript
// Apply early (before DOMContentLoaded) to prevent flash:
(function() {
  if (localStorage.getItem('booth_theme') === 'light') {
    document.documentElement.classList.add('light-theme');
  }
})();

// Toggle:
function toggleTheme() {
  const isLight = document.documentElement.classList.toggle('light-theme');
  localStorage.setItem('booth_theme', isLight ? 'light' : 'dark');
}
```

**CSS additions** (light-theme overrides at the bottom of the `<style>` block):
```css
.light-theme {
  --bg: #f8fafc;
  --card: #ffffff;
  --card-border: #e2e8f0;
  --text: #0f172a;
  --text-dim: #475569;
  --text-muted: #94a3b8;
  --inactive-bg: #f1f5f9;
  --inactive-border: #cbd5e1;
  --signature-bg: #f8fafc;
}
```

**Gotcha**: The early-apply IIFE must be placed in a `<script>` tag immediately after `<html>` opens (before `<head>`) or at the very top of the `<head>` — before the `<style>` block if possible. Placing it after the style block still avoids a flash because CSS variable resolution is lazy.

---

## Section 5: PIN Change Flow

### Decision: Verify current PIN client-side, hash new PIN with Web Crypto, UPDATE settings via Supabase anon key (with new RLS migration)

**Rationale**: The existing Phase 3 PIN verification pattern already uses `crypto.subtle.digest('SHA-256', ...)` and compares against the stored hash. The PIN change flow reuses this: hash the entered current PIN, compare against DB, if match then hash the new PIN and UPDATE.

**RLS requirement**: The `settings` table currently only has anon SELECT. A new migration is needed to add anon UPDATE. This is the same pattern used in Phase 3 (staff write RLS) and Phase 4 (events write RLS).

**Migration**:
```sql
-- 004_settings_dashboard_rls.sql
CREATE POLICY "anon can update settings"
  ON settings FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
```

**Implementation**:
```javascript
async function submitPinChange() {
  const currentPin = document.getElementById('currentPinInput').value;
  const newPin = document.getElementById('newPinInput').value;
  const confirmPin = document.getElementById('confirmPinInput').value;

  // 1. Validate new PIN format
  if (newPin.length !== 4 || !/^\d{4}$/.test(newPin)) { showError(...); return; }
  if (newPin !== confirmPin) { showError(...); return; }

  // 2. Hash current PIN and compare against DB
  const currentHash = await hashPin(currentPin);
  const { data } = await _supabase.from('settings').select('pin_hash').eq('id', 1).single();
  if (currentHash !== data.pin_hash) { showError('رمز PIN الحالي غير صحيح'); return; }

  // 3. Hash new PIN and UPDATE
  const newHash = await hashPin(newPin);
  await _supabase.from('settings').update({ pin_hash: newHash }).eq('id', 1);
  showToast('تم تغيير رمز PIN بنجاح ✓');
  clearPinChangeForm();
}
```

**`hashPin()`** already exists in `dashboard.html` — reuse it directly.

---

## Section 6: Export Section UX

### Decision: Add "تصدير" and "الإعدادات" as 4th and 5th tabs in the existing tab bar

**Rationale**: Consistent with the existing tab pattern in Phase 4. No new HTML file needed. `switchTab('export')` and `switchTab('settings')` follow the exact same pattern as existing tabs.

**Export section layout**:
- Event selector (reuses `EVENTS[]` already loaded)
- Record count preview line: "سيتم تصدير N سجل"
- Three export buttons: CSV, نصي, PDF
- Error state when count = 0

**Settings section layout**:
- PIN Change card: three inputs (current, new, confirm) + save button
- Theme toggle: labelled switch

---

## Section 7: File Naming

**Decision**: Sanitise event name for filename by replacing spaces with hyphens and removing non-alphanumeric Arabic/Latin characters.

```javascript
function safeFilename(eventName) {
  return eventName.replace(/\s+/g, '-').replace(/[^\u0600-\u06FF\w-]/g, '') || 'attendance';
}
// Usage: `${safeFilename(event.name)}-attendance.csv`
```
