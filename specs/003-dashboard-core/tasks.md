# Tasks: Phase 3 — Dashboard Core

**Input**: Design documents from `/specs/003-dashboard-core/`  
**Branch**: `003-dashboard-core`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: No test tasks generated — manual verification via quickstart.md.

**Organization**: All implementation goes into one new file (`dashboard.html`) plus one new SQL migration file. Tasks build up incrementally — each phase produces a testable increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (independent sections, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)

---

## Phase 1: Setup

**Purpose**: Create the migration file and the `dashboard.html` skeleton before any logic is written.

- [x] T001 Create `supabase/migrations/001_staff_dashboard_rls.sql` with `CREATE POLICY "anon can insert staff" ON staff FOR INSERT TO anon WITH CHECK (true);` and `CREATE POLICY "anon can update staff" ON staff FOR UPDATE TO anon USING (true) WITH CHECK (true);`
- [x] T002 Apply `supabase/migrations/001_staff_dashboard_rls.sql` in the Supabase SQL Editor (manual step — run both statements and confirm no errors)
- [x] T003 Create `dashboard.html` with the full `<head>` block: `lang="ar" dir="rtl"`, Tajawal Google Font link, Supabase CDN script, `config.js` script, and an empty `<style>` block and empty `<body>`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the complete CSS theme, shared HTML structure (header + toast), and the Supabase client + helper functions to `dashboard.html`. All user story phases depend on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 Add CSS to `dashboard.html`: copy the `:root` CSS variables block from `booth-attendance.html` (all `--bg`, `--card`, `--accent`, `--danger`, `--text-*`, etc.), then add `.hidden { display: none !important; }` and `.toast` / `.toast.show` rules
- [x] T005 [P] Add CSS to `dashboard.html` for layout: `body`, `.header`, `.header h1`, `.header p`, `.logout-btn` positioned top-left (mirror of `.menu-btn` pattern from `booth-attendance.html`)
- [x] T006 [P] Add CSS to `dashboard.html` for staff cards: `.staff-list`, `.staff-card`, `.staff-card.inactive`, `.staff-info`, `.avatar`, `.staff-name`, `.staff-status`, `.card-actions`, `.btn-icon` (edit and delete icon buttons)
- [x] T007 [P] Add CSS to `dashboard.html` for modals: `.modal-overlay`, `.modal-overlay.active`, `.modal`, `.modal h2`, `.modal input`, `.modal-actions`, `.btn`, `.btn-primary`, `.btn-cancel`, `.modal-error`
- [x] T008 [P] Add CSS to `dashboard.html` for PIN screen: `.pin-screen`, `.pin-screen h2`, `.pin-input`, `.pin-submit`, `.pin-error`, and delete-confirm inline row `.delete-confirm`
- [x] T009 Add HTML shell to `<body>` of `dashboard.html`: `#pinScreen` div (PIN entry UI placeholder), `#dashboard` div with class `hidden` (staff management UI placeholder), `#toast` div, `#staffModal` overlay div (modal placeholder)
- [x] T010 Add the `<script>` block to `dashboard.html` with: config guard + `_supabase` init (same pattern as `booth-attendance.html`), all state variables (`STAFF`, `searchQuery`, `modalMode`, `editStaffId`, `deleteConfirmId`), `showFatalError()`, `showToast()`, and `document.addEventListener('DOMContentLoaded', init)`

**Checkpoint**: `dashboard.html` opens in a browser without errors. Console shows no JS errors. Page is visually blank (no content yet).

---

## Phase 3: User Story 1 — PIN Gate (Priority: P1) 🎯 MVP

**Goal**: The dashboard is fully locked behind a PIN screen. Wrong PIN is rejected. Correct PIN unlocks the session. Logout clears the session.

**Independent Test**: Open `dashboard.html` — only PIN screen visible. Enter `0000` → error shown, screen stays locked. Enter `1234` → dashboard area revealed. Refresh — dashboard stays unlocked (session). Click logout → PIN screen returns.

- [x] T011 [US1] Build the PIN screen HTML inside `#pinScreen` in `dashboard.html`: `<h2>لوحة التحكم</h2>`, a 4-digit `<input id="pinInput" type="password" maxlength="4" inputmode="numeric">`, a `<button id="pinSubmit" disabled>دخول</button>`, and a `<div id="pinError" class="pin-error hidden"></div>`
- [x] T012 [US1] Add `showPinScreen()` and `showDashboard()` functions to `dashboard.html`: toggle `hidden` class between `#pinScreen` and `#dashboard`
- [x] T013 [US1] Add `showPinError(message)` function to `dashboard.html`: sets `#pinError` text, removes `hidden` class; and wire `#pinInput` `input` event to enable `#pinSubmit` only when `pinInput.value.length === 4` and hide `#pinError`
- [x] T014 [US1] Add `async hashPin(pin)` function to `dashboard.html` using `crypto.subtle.digest('SHA-256', new TextEncoder().encode(pin))`, converting the resulting ArrayBuffer to a 64-char lowercase hex string
- [x] T015 [US1] Add `async submitPin()` function to `dashboard.html`: fetch `pin_hash` from `settings WHERE id=1`, call `hashPin(pinInput.value)`, compare — on match call `sessionStorage.setItem('dashboard_auth','1')` then `showDashboard()` then `loadStaff()`; on mismatch call `showPinError('رمز PIN غير صحيح')` and clear `#pinInput`; handle DB error with `showPinError('خطأ في الإعدادات')`
- [x] T016 [US1] Add `logout()` function to `dashboard.html`: `sessionStorage.removeItem('dashboard_auth')`, call `showPinScreen()`, clear `#pinInput`; add a logout button to `#dashboard` header with `onclick="logout()"`
- [x] T017 [US1] Implement `async init()` in `dashboard.html`: config guard → `_supabase = supabase.createClient(...)` → check `sessionStorage.getItem('dashboard_auth') === '1'` → if yes call `showDashboard()` then `loadStaff()`, if no call `showPinScreen()`; wire `#pinSubmit` click and `#pinInput` keydown (Enter key) to call `submitPin()`

**Checkpoint**: PIN gate works end-to-end. Session persists across navigation. Logout clears session.

---

## Phase 4: User Story 2 — Staff List (Priority: P1)

**Goal**: After unlocking, the admin sees all staff members (active + inactive) ordered alphabetically, with visual differentiation and a working real-time search box.

**Independent Test**: Unlock with PIN `1234` → verify 5 seeded names appear alphabetically. Set one staff member to `is_active=false` in SQL Editor → verify they appear dimmed with "غير نشط". Type part of a name in search → list filters instantly.

- [x] T018 [US2] Build the dashboard HTML inside `#dashboard` in `dashboard.html`: a header bar with title "إدارة الموظفين" and logout button, a search row with `<input id="searchInput" type="text" placeholder="بحث عن موظف...">` and an `<button onclick="openStaffModal('add')">إضافة موظف ＋</button>`, and a `<div id="staffList"></div>` container
- [x] T019 [US2] Add `async loadStaff()` function to `dashboard.html`: fetch `SELECT id, name, is_active, created_at FROM staff ORDER BY name` → assign to `STAFF` → call `renderStaffList()`; on error show Arabic error message in `#staffList`
- [x] T020 [US2] Add `renderStaffList()` function to `dashboard.html`: filter `STAFF` by `searchQuery` (case-insensitive `includes`), render each staff member as a card showing avatar initials, name, status badge (`حاضر`/`غير نشط`), edit button, and delete button (only for active staff); show empty-state message if no results
- [x] T021 [US2] Wire `#searchInput` `input` event in `dashboard.html`: set `searchQuery = e.target.value.trim()` → call `renderStaffList()`
- [x] T022 [US2] Add `getInitials(name)` helper to `dashboard.html` (same logic as `booth-attendance.html`: split on space, take first char of first two parts)

**Checkpoint**: Staff list renders from DB. Search filters in real time. Active vs inactive cards look visually distinct.

---

## Phase 5: User Story 3 — Add Staff (Priority: P1)

**Goal**: Admin can open a modal, enter a name, and save. New staff member appears immediately in the list and is persisted to the database.

**Independent Test**: Click "إضافة موظف" → modal opens with empty field. Submit empty → validation error. Enter "موظف اختبار" and submit → modal closes, name appears in list. Verify in Supabase SQL Editor.

- [x] T023 [US3] Build the staff modal HTML inside `#staffModal` in `dashboard.html`: `.modal-overlay` wrapping a `.modal` with `<h2 id="modalTitle"></h2>`, `<input id="staffNameInput" type="text" placeholder="اسم الموظف">`, `<div id="modalError" class="modal-error hidden"></div>`, and two buttons: `<button onclick="submitStaffModal()">حفظ</button>` and `<button onclick="closeStaffModal()">إلغاء</button>`; close on overlay click
- [x] T024 [US3] Add `openStaffModal(mode, staff)` function to `dashboard.html`: set `modalMode` and `editStaffId`, set `#modalTitle` text (`إضافة موظف` or `تعديل الاسم`), pre-fill `#staffNameInput` (empty for add, `staff.name` for edit), show `#staffModal` by adding `.active`, focus `#staffNameInput`
- [x] T025 [US3] Add `closeStaffModal()` function to `dashboard.html`: remove `.active` from `#staffModal`, reset `modalMode = null`, `editStaffId = null`, clear `#staffNameInput` and `#modalError`
- [x] T026 [US3] Add `async submitStaffModal()` function to `dashboard.html` for the **add** case only: validate name not empty (show `#modalError` if empty); INSERT `{name}` into `staff` table with `.select('id, name, is_active, created_at').single()`; on success push result to `STAFF`, call `renderStaffList()`, call `closeStaffModal()`; on error show `#modalError`

**Checkpoint**: Add staff modal opens, validates, saves to DB, updates list immediately.

---

## Phase 6: User Story 4 — Edit Staff (Priority: P2)

**Goal**: Admin can click edit on any staff card, change the name, and save. Updated name reflects immediately.

**Independent Test**: Click edit on any card → modal pre-filled with current name. Change name and save → modal closes, updated name in list. Verify in SQL Editor.

- [x] T027 [US4] Extend `async submitStaffModal()` in `dashboard.html` to handle the **edit** case: when `modalMode === 'edit'`, UPDATE `staff SET name=$name WHERE id=$editStaffId` with `.select('id, name, is_active, created_at').single()`; on success find and replace the entry in `STAFF[]`, call `renderStaffList()`, call `closeStaffModal()`; on error show `#modalError`

**Checkpoint**: Edit modal pre-fills existing name, saves update to DB, and reflects change immediately in list.

---

## Phase 7: User Story 5 — Soft-Delete Staff (Priority: P2)

**Goal**: Admin can soft-delete a staff member with a confirmation step. The member disappears from the attendance page but remains in the dashboard list as inactive.

**Independent Test**: Click delete on an active staff card → inline confirm row appears. Click cancel → card returns to normal. Click delete again, confirm → card shows "غير نشط". Open `booth-attendance.html` and refresh → deleted member absent. Verify `is_active=false` in SQL Editor.

- [x] T028 [US5] Update `renderStaffList()` in `dashboard.html` to render an inline delete-confirm row when `deleteConfirmId === staff.id`: replace action buttons with "تأكيد الحجب" and "إلغاء" buttons (call `confirmDelete(staff.id)` and `cancelDelete()` respectively)
- [x] T029 [US5] Add `showDeleteConfirm(staffId)` function to `dashboard.html`: set `deleteConfirmId = staffId` → call `renderStaffList()`
- [x] T030 [US5] Add `cancelDelete()` function to `dashboard.html`: set `deleteConfirmId = null` → call `renderStaffList()`
- [x] T031 [US5] Add `async confirmDelete(staffId)` function to `dashboard.html`: UPDATE `staff SET is_active=false WHERE id=staffId`; on success find entry in `STAFF[]`, set `is_active=false`, set `deleteConfirmId=null`, call `renderStaffList()`, call `showToast('تم حجب الموظف ✓')`; on error call `showToast('❌ فشل الحجب')` and reset `deleteConfirmId`

**Checkpoint**: Delete shows inline confirm. Confirm soft-deletes in DB. Cancelled delete restores card. Deleted member absent from attendance page.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T032 [P] Add keyboard accessibility to `dashboard.html`: `#staffNameInput` should submit on Enter key (`keydown` listener calling `submitStaffModal()`); `#staffModal` overlay click closes modal (call `closeStaffModal()` when `e.target === overlay`)
- [x] T033 [P] Add empty-state message to `renderStaffList()` in `dashboard.html` for when `STAFF` is empty after load (not after search): "لا يوجد موظفون بعد — أضف أول موظف"
- [x] T034 Follow `specs/003-dashboard-core/quickstart.md` Steps 1–11 to validate the complete implementation end-to-end

---

## Dependencies & Execution Order

```
Phase 1 (Setup) → Phase 2 (Foundation)
                        ↓
               Phase 3: US1 PIN Gate (P1) 🎯
                        ↓
               Phase 4: US2 Staff List (P1)
                        ↓
               Phase 5: US3 Add Staff (P1)
                   ↓            ↓
          Phase 6: US4       Phase 7: US5
          Edit Staff (P2)    Soft-Delete (P2)  ← can run in parallel (different functions)
                   ↓            ↓
               Phase 8: Polish
```

- **Setup (Phase 1)**: Start immediately — creates migration + skeleton file
- **Foundation (Phase 2)**: Depends on Phase 1 — CSS, HTML shell, client init, helpers
- **US1 PIN Gate (Phase 3)**: Depends on Phase 2 — entire auth flow
- **US2 Staff List (Phase 4)**: Depends on Phase 3 — needs dashboard visible after auth
- **US3 Add Staff (Phase 5)**: Depends on Phase 4 — modal added to existing staff list
- **US4 Edit (Phase 6)** and **US5 Soft-Delete (Phase 7)**: Both depend on Phase 5; can run in parallel (edit extends `submitStaffModal`, delete adds new functions)
- **Polish (Phase 8)**: Depends on all stories complete

### Within-Phase Parallel Opportunities

- T005, T006, T007, T008: All CSS blocks — different selectors, no dependencies
- T032, T033: Different functions in Polish phase

---

## Parallel Execution Example: Phase 2 Foundation CSS

```
# T004 must run first (defines CSS variables used by all others)
Task T004: Add :root variables + .hidden + .toast CSS to dashboard.html

# Then T005-T008 can run simultaneously (different CSS sections):
Task T005: Add body/header/logout CSS to dashboard.html      ← parallel
Task T006: Add staff card CSS to dashboard.html              ← parallel
Task T007: Add modal CSS to dashboard.html                   ← parallel
Task T008: Add PIN screen + delete-confirm CSS to dashboard.html ← parallel
```

---

## Implementation Strategy

### MVP Scope: US1 + US2 + US3 (Phases 1–5, T001–T026)

This gives a working dashboard with:
- PIN protection
- Full staff list with search
- Ability to add new staff members

The attendance page will immediately reflect any new staff added via the dashboard.

### Incremental Delivery

1. Phase 1+2: Skeleton + CSS + helpers → blank styled page, no errors
2. Phase 3 (US1): PIN gate → security boundary working ✓
3. Phase 4 (US2): Staff list + search → admin can see all staff ✓
4. Phase 5 (US3): Add staff → admin can grow the team ✓ ← **MVP complete**
5. Phase 6 (US4): Edit staff → admin can fix names ✓
6. Phase 7 (US5): Soft-delete → admin can retire staff ✓
7. Phase 8: Polish → keyboard nav, empty states, end-to-end validation ✓

---

## Notes

- `dashboard.html` is a brand new file — no existing code to preserve
- The migration (T001–T002) **must** be applied before any staff write operations will work
- The delete confirmation is an inline row on the card (no overlay modal) — simpler and consistent with the mobile RTL layout
- `renderStaffList()` is called by multiple actions (search, add, edit, delete) — keep it a pure render function with no side effects
- The `STAFF[]` array is the single source of truth during a session; updates to DB are always reflected back into `STAFF[]` on success before re-rendering
