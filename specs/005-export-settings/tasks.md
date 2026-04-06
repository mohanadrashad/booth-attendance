# Tasks: Phase 5 — Export & Settings

**Input**: Design documents from `/specs/005-export-settings/`  
**Branch**: `005-export-settings`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: No test tasks generated — manual verification via quickstart.md.

**Organization**: All implementation is in `dashboard.html` plus one new migration file. Tasks build incrementally — migration first, then foundational CSS/HTML/state, then Export section (US1), then Settings section (US2 + US3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (independent sections, no shared logic dependencies)
- **[Story]**: Which user story this task belongs to (US1–US3)

---

## Phase 1: Setup

**Purpose**: Create the migration file for settings RLS before any code changes.

- [X] T001 Create `supabase/migrations/004_settings_dashboard_rls.sql` with: `CREATE POLICY "anon can update settings" ON settings FOR UPDATE TO anon USING (true) WITH CHECK (true);`
- [ ] T002 Apply `supabase/migrations/004_settings_dashboard_rls.sql` in the Supabase SQL Editor (manual step)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add "تصدير" and "الإعدادات" tabs to the tab bar, their section divs, new state variables, CSS for the export and settings sections, and the early-apply theme IIFE. All user story sections depend on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Add early-apply theme IIFE to `dashboard.html` — insert `<script>(function(){ if(localStorage.getItem('booth_theme')==='light') document.documentElement.classList.add('light-theme'); })()</script>` as the very first `<script>` tag inside `<head>`, before the `<style>` block
- [X] T004 Add CSS for light-theme overrides to `dashboard.html` at the bottom of the `<style>` block: `.light-theme { --bg:#f8fafc; --card:#ffffff; --card-border:#e2e8f0; --text:#0f172a; --text-dim:#475569; --text-muted:#94a3b8; --inactive-bg:#f1f5f9; --inactive-border:#cbd5e1; --signature-bg:#f8fafc; }`
- [X] T005 [P] Add CSS for export section to `dashboard.html`: `.export-preview` (padding 14px 16px, font-size 14px, color var(--text-dim)), `.export-actions` (display flex, gap 10px, padding 14px 16px, flex-wrap wrap), `.btn-export` (flex 1, min-width 100px, padding 12px 16px, background var(--card), border 1px solid var(--card-border), border-radius 12px, font-family Tajawal, font-size 14px, font-weight 600, color var(--text), cursor pointer, transition opacity 0.2s), `.btn-export:disabled` (opacity 0.35, cursor not-allowed)
- [X] T006 [P] Add CSS for settings section to `dashboard.html`: `.settings-card` (background var(--card), border 1px solid var(--card-border), border-radius 14px, padding 20px, margin 14px 16px), `.settings-card h3` (font-size 15px, font-weight 700, margin-bottom 16px), `.settings-row` (display flex, align-items center, justify-content space-between, gap 12px, margin-bottom 12px), `.settings-label` (font-size 14px, color var(--text-dim)), `.toggle-switch` (position relative, width 44px, height 24px), `.toggle-switch input` (opacity 0, width 0, height 0), `.toggle-switch .slider` (position absolute, inset 0, background var(--card-border), border-radius 24px, transition 0.2s), `.toggle-switch input:checked + .slider` (background var(--accent)), `.toggle-switch .slider:before` (position absolute, content "", height 18px, width 18px, left 3px, bottom 3px, background white, border-radius 50%, transition 0.2s), `.toggle-switch input:checked + .slider:before` (transform translateX(20px))
- [X] T007 Add two new tab buttons to the tab bar in `dashboard.html` — append after the "الحضور" button: `<button class="tab-btn" data-tab="export" onclick="switchTab('export')">تصدير</button>` and `<button class="tab-btn" data-tab="settings" onclick="switchTab('settings')">الإعدادات</button>`
- [X] T008 Add `<div id="section-export" class="tab-section hidden"></div>` and `<div id="section-settings" class="tab-section hidden"></div>` after `#section-attendance` in `dashboard.html`
- [X] T009 Add new state variables to the script block of `dashboard.html` after the existing state block: `let exportSelectedEventId = null;` and `let exportRecordCount = 0;`
- [X] T010 Extend `switchTab(tab)` in `dashboard.html` to handle `tab === 'export'` (calls `loadExport()`) and `tab === 'settings'` (calls `loadSettings()`) — add these two cases to the existing if-block at the end of the function

**Checkpoint**: Open `dashboard.html`, unlock with PIN — five tabs visible: الموظفون, الفعاليات, الحضور, تصدير, الإعدادات. Clicking each shows its (empty) section.

---

## Phase 3: User Story 1 — Export Attendance Report (Priority: P1) 🎯 MVP

**Goal**: Admin can export attendance records for any event as CSV, text, or PDF with signatures.

**Independent Test**: Click "تصدير" tab → event selector shows events with record counts → click "تصدير CSV" → `.csv` file downloads with correct rows. Click "تصدير نصي" → clipboard/share. Click "تصدير PDF" → print window opens. Select event with 0 records → all buttons disabled.

- [X] T011 [US1] Add Export section HTML inside `#section-export` in `dashboard.html`: `<div class="toolbar"><select id="exportEventSelector" class="event-select"></select></div>`, `<div id="exportPreview" class="export-preview"></div>`, `<div class="export-actions"><button id="btnExportCSV" class="btn-export" onclick="exportCSV()">تصدير CSV</button><button id="btnExportText" class="btn-export" onclick="exportText()">تصدير نصي</button><button id="btnExportPDF" class="btn-export" onclick="exportPDF()">تصدير PDF</button></div>`
- [X] T012 [US1] Add `loadExport()` function to `dashboard.html`: if `EVENTS[]` is empty show "لا توجد فعاليات — أنشئ فعالية أولاً" in `#exportPreview` and disable buttons, else set `exportSelectedEventId` to active event ID (or `EVENTS[0].id`); populate `#exportEventSelector` options from `EVENTS[]` (active event labelled with "●"); wire `#exportEventSelector` change → `exportSelectedEventId = e.target.value; updateExportPreview()`; call `updateExportPreview()`
- [X] T013 [US1] Add `async updateExportPreview()` function to `dashboard.html`: count records `SELECT id FROM attendance WHERE event_id=exportSelectedEventId (count:'exact', head:true)`; assign to `exportRecordCount`; update `#exportPreview` text to "سيتم تصدير N سجل"; if count === 0 disable `#btnExportCSV`, `#btnExportText`, `#btnExportPDF`, else enable them
- [X] T014 [US1] Add `safeFilename(eventName)` pure function to `dashboard.html`: replaces spaces with `-`, strips non-Arabic non-word chars, falls back to `'attendance'` if empty
- [X] T015 [US1] Add `async exportCSV()` function to `dashboard.html`: guard `exportRecordCount === 0`; fetch `SELECT checked_in_at, staff:staff_id(name) FROM attendance WHERE event_id=exportSelectedEventId ORDER BY checked_in_at`; find event in `EVENTS[]`; build CSV string with UTF-8 BOM `'\uFEFF'`, header row `"الاسم","وقت الحضور"`, one row per record (name, HH:MM time, both double-quoted); trigger download via `Blob + URL.createObjectURL + <a>.click()`; filename `${safeFilename(event.name)}-attendance.csv`
- [X] T016 [US1] Add `async exportText()` function to `dashboard.html`: guard `exportRecordCount === 0`; fetch same records; find event; build multi-line Arabic text report (event name header, date, total count, separator, numbered list of "name — HH:MM"); try `navigator.share({text, title})`, fallback to `navigator.clipboard.writeText(text)` with `showToast('تم نسخ التقرير ✓')`, catch → `showToast('❌ فشل المشاركة', true)`
- [X] T017 [US1] Add `async exportPDF()` function to `dashboard.html`: guard `exportRecordCount === 0`; fetch `SELECT checked_in_at, signature_data, staff:staff_id(name) FROM attendance WHERE event_id=exportSelectedEventId ORDER BY checked_in_at`; find event; build full print HTML string (see contracts/js-functions.md Section exportPDF for exact structure: `<!DOCTYPE html><html dir="rtl">`, Tajawal font link, print CSS, header with event name+date, table with columns #/الاسم/وقت الحضور/التوقيع, `<img src="[signature_data]">` per row or empty td if null); `const w = window.open('','_blank'); w.document.write(html); w.document.close(); w.onload = () => { w.focus(); w.print(); }`
- [X] T018 [US1] Wire `loadExport()` call in `init()` so `#exportEventSelector` change listener is added once; also ensure `loadExport()` is called from `loadEvents()` (or after `loadEvents()` resolves) so `EVENTS[]` is populated before export tab is opened

**Checkpoint**: Export tab fully functional. CSV downloads with correct UTF-8 content. Text export copies/shares. PDF print window opens with signatures. Zero-record guard blocks buttons.

---

## Phase 4: User Story 2 — Change Dashboard PIN (Priority: P2)

**Goal**: Admin can change the dashboard PIN after verifying the current one. New PIN takes effect immediately.

**Independent Test**: Settings tab → enter current PIN `1234`, new PIN `5678`, confirm `5678` → save → toast. Log out → try `1234` fails → try `5678` succeeds. Reset back to `1234`.

- [X] T019 [US2] Add Settings section HTML inside `#section-settings` in `dashboard.html`: PIN change card with `<div class="settings-card">`, `<h3>تغيير رمز PIN</h3>`, three `.modal-input` fields (`id="currentPinInput"` placeholder="رمز PIN الحالي", `id="newPinInput"` placeholder="رمز PIN الجديد", `id="confirmPinInput"` placeholder="تأكيد رمز PIN الجديد"), all `type="password" maxlength="4" inputmode="numeric"`, `<div id="pinChangeError" class="modal-error hidden"></div>`, `<button id="btnSavePin" class="btn-primary" onclick="submitPinChange()">حفظ</button>`
- [X] T020 [US2] Add `loadSettings()` function to `dashboard.html`: sets `#themeToggle` checked state from `document.documentElement.classList.contains('light-theme')`; clears PIN inputs and hides `#pinChangeError`
- [X] T021 [US2] Add `async submitPinChange()` function to `dashboard.html` per contracts/js-functions.md: validate `newPin` is exactly 4 digits (`/^\d{4}$/`); validate `newPin === confirmPin`; disable `#btnSavePin`; hash current PIN via existing `hashPin()`; fetch `pin_hash` from settings; compare — if mismatch show error; hash new PIN; UPDATE settings SET pin_hash=newHash WHERE id=1; on success `showToast('تم تغيير رمز PIN بنجاح ✓')` and `clearPinChangeForm()`; on DB error show `#pinChangeError`; re-enable button
- [X] T022 [US2] Add `clearPinChangeForm()` function to `dashboard.html`: clears `#currentPinInput`, `#newPinInput`, `#confirmPinInput`; hides `#pinChangeError`; re-enables `#btnSavePin`
- [X] T023 [US2] Wire PIN input events in `init()` in `dashboard.html`: `#newPinInput` 'input' → disable `#btnSavePin` if value.length !== 4; all three PIN inputs 'keydown' → call `submitPinChange()` on Enter if `newPinInput.value.length === 4`

**Checkpoint**: PIN change validates correctly (wrong current, mismatch confirm, too short). Successful change takes effect on next login.

---

## Phase 5: User Story 3 — Theme Toggle (Priority: P3)

**Goal**: Admin can switch between dark and light themes. Preference persists across refreshes.

**Independent Test**: Settings tab → toggle theme switch → immediate visual change → refresh → theme persists → toggle back → dark mode returns.

- [X] T024 [US3] Add theme toggle HTML to `#section-settings` in `dashboard.html` (inside a second `.settings-card` after the PIN card): `<h3>المظهر</h3>`, `<div class="settings-row"><span class="settings-label">الوضع الفاتح</span><label class="toggle-switch"><input type="checkbox" id="themeToggle" onchange="toggleTheme()"><span class="slider"></span></label></div>`
- [X] T025 [US3] Add `toggleTheme()` function to `dashboard.html`: `const isLight = document.documentElement.classList.toggle('light-theme'); localStorage.setItem('booth_theme', isLight ? 'light' : 'dark')`

**Checkpoint**: Theme switches immediately on toggle. Preference survives page refresh. `loadSettings()` correctly reflects current theme state in the checkbox.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T026 [P] Verify `loadExport()` is called when `EVENTS[]` might be empty (e.g., user navigates to Export tab before events load) — add empty-state guard in `loadExport()` that re-checks `EVENTS[]` and shows "لا توجد فعاليات" in `dashboard.html`
- [X] T027 [P] Verify `logout()` in `dashboard.html` resets `exportSelectedEventId = null` and `exportRecordCount = 0` so stale export state doesn't persist to next session
- [ ] T028 Follow `specs/005-export-settings/quickstart.md` Steps 1–10 to validate the complete implementation end-to-end

---

## Dependencies & Execution Order

```
Phase 1 (Setup: migration) → Phase 2 (Foundation: tabs + CSS + state)
                                       ↓
                        Phase 3: US1 Export (P1) 🎯
                                       ↓
                        Phase 4: US2 PIN Change (P2)
                                       ↓
                        Phase 5: US3 Theme Toggle (P3)
                                       ↓
                              Phase 6: Polish
```

- **Setup (Phase 1)**: T001 (create file) in parallel with nothing else; T002 is manual
- **Foundation (Phase 2)**: T003–T010; T004–T006 can be parallel (different CSS blocks); T007–T010 sequential (shared HTML/JS)
- **US1 Export (Phase 3)**: Depends on Phase 2 — T011 HTML → T012 loadExport → T013 updateExportPreview → T014 safeFilename → T015–T017 three export functions → T018 wiring
- **US2 PIN Change (Phase 4)**: Depends on Phase 2 + Phase 3 complete (uses shared Settings section HTML added alongside Export section); T019 HTML → T020 loadSettings → T021 submitPinChange → T022 clearPinChangeForm → T023 wiring
- **US3 Theme (Phase 5)**: Depends on Phase 4 (extends Settings section HTML from T019); T024 HTML → T025 toggleTheme
- **Polish (Phase 6)**: T026 + T027 parallel, then T028

### Parallel Opportunities

- T001 (migration file creation) can run any time
- T004, T005, T006: Different CSS additions — can be written in one edit pass
- T015, T016, T017: Different export functions — no shared dependencies after T014

---

## Implementation Strategy

### MVP Scope: Phases 1–3 (T001–T018)

This gives:
- Migration applied
- Two new tabs (Export + Settings stubs)
- Full Export section: CSV + text + PDF, event selector, record count preview, zero-guard

### Incremental Delivery

1. Phases 1+2: Migration + tab nav foundation → two new tabs visible ✓
2. Phase 3 (US1): Export CSV, text, PDF → complete export capability ✓ ← **MVP**
3. Phase 4 (US2): PIN change → self-service security ✓
4. Phase 5 (US3): Theme toggle → appearance preference ✓
5. Phase 6: Polish → edge cases, end-to-end validation ✓

---

## Notes

- All tasks modify only `dashboard.html` (except the migration file)
- `EVENTS[]` is already loaded at login (Phase 4 T033) — Export tab reuses it directly
- `hashPin()` already exists in `dashboard.html` — reused by `submitPinChange()` with no changes
- The early-apply theme IIFE (T003) must be the very first `<script>` in `<head>` to prevent flash
- The toggle switch CSS (T006) uses a pure CSS checkbox + label technique — no JS needed for the visual animation
- Phase 5 (US3) extends the Settings section HTML created in Phase 4 (US2) — these phases must stay sequential
