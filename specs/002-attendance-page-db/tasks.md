# Tasks: Phase 2 — Attendance Page (DB Connected)

**Input**: Design documents from `/specs/002-attendance-page-db/`  
**Branch**: `002-attendance-page-db`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: No test tasks generated — no automated test framework in scope. Manual verification steps are in `quickstart.md`.

**Organization**: All changes are confined to `booth-attendance.html`. Tasks are ordered to build up the data layer incrementally — each phase produces a independently testable increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different sections of the file, no shared logic dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add Supabase CDN and config.js to the HTML head, and wire up the client initialization. Nothing else works until this is in place.

- [x] T001 Add `<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>` to `<head>` of `booth-attendance.html`, before any other script tags
- [x] T002 Add `<script src="config.js"></script>` to `<head>` of `booth-attendance.html`, immediately after the Supabase CDN script tag

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Replace hardcoded state variables, initialize the Supabase client, add helper functions, and add the loading overlay element. Every user story depends on this infrastructure.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Replace `const STAFF = [...]` with `let STAFF = [];` and add `let currentEvent = null;` in the variables section at the top of the `<script>` block in `booth-attendance.html`
- [x] T004 Add `const _supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);` at the very top of the `<script>` block in `booth-attendance.html`, before any function definitions
- [x] T005 Add `showLoading(visible)` function to `booth-attendance.html`: toggles `hidden` class on `#loadingOverlay` (show) and `#staffList` (hide) — see contracts/js-functions.md
- [x] T006 [P] Add `showError(message)` function to `booth-attendance.html`: renders an Arabic error message into the `#staffList` area when a DB query fails on load
- [x] T007 [P] Add `showFatalError(message)` function to `booth-attendance.html`: replaces page content area with a non-recoverable Arabic error message (used when config.js is missing)
- [x] T008 Add `<div id="loadingOverlay" class="loading-overlay hidden"><span>جارٍ التحميل...</span></div>` inside the `#staffList` container in the HTML section of `booth-attendance.html`
- [x] T009 Add `.loading-overlay` CSS rule to the `<style>` block in `booth-attendance.html`: centered flex layout, Arabic text, using existing CSS variable `--text-muted`

**Checkpoint**: The Supabase client is initialized, helper functions exist, and the loading overlay is in place. User story phases can now build on this foundation.

---

## Phase 3: User Story 1 — Staff Grid Loads from Database (Priority: P1) 🎯 MVP

**Goal**: Replace the hardcoded staff array with a live database query. The staff grid renders from real data.

**Independent Test**: Open `booth-attendance.html`, verify the 5 seeded Arabic staff names appear (not the old hardcoded names). Then add a new row to the `staff` table in the Supabase SQL Editor, refresh, and confirm the new name appears.

- [x] T010 [US1] Convert `init()` to `async function init()` in `booth-attendance.html` and replace the direct `init()` call at the bottom of the script with `document.addEventListener('DOMContentLoaded', init);`
- [x] T011 [US1] Add config guard at the start of `init()`: check `typeof SUPABASE_URL === 'undefined'` — call `showFatalError('ملف الإعدادات مفقود. يرجى إنشاء ملف config.js')` and return if missing — in `booth-attendance.html`
- [x] T012 [US1] Add `showLoading(true)` at the start of `init()` and `showLoading(false)` in a `finally` block at the end in `booth-attendance.html`
- [x] T013 [US1] Inside `init()`, fetch active staff with `await _supabase.from('staff').select('id, name').eq('is_active', true).order('name')` and assign result to `STAFF`; call `showError()` and return if query errors — in `booth-attendance.html`

**Checkpoint**: Staff grid renders from database. Hardcoded STAFF array is gone. Loading indicator works.

---

## Phase 4: User Story 2 — Active Event Loads and Displays (Priority: P1)

**Goal**: Fetch the active event from the database and display its name in the header. Block check-ins if no active event exists.

**Independent Test**: Verify the event name "معرض الكتاب 2026" (or your active event) appears in the header. Then set all events to `is_active = false` in the SQL Editor, refresh, and confirm check-in cards become non-interactive with an explanatory message.

- [x] T014 [US2] Inside `init()`, fetch the active event with `await _supabase.from('events').select('id, name, event_date').eq('is_active', true).maybeSingle()` and assign to `currentEvent`; if result is null, set `currentEvent = null` — in `booth-attendance.html`
- [x] T015 [US2] Update the header date/event display in `init()` to use `currentEvent.name` and `currentEvent.event_date` when available, falling back to today's date when `currentEvent` is null — in `booth-attendance.html`
- [x] T016 [US2] Update `renderStaff()` in `booth-attendance.html`: when `currentEvent === null`, render a single full-width message card "لا يوجد حدث نشط — يرجى التواصل مع المسؤول" and skip rendering interactive staff cards

**Checkpoint**: Event name shows in header. Missing active event blocks all check-ins with an Arabic message.

---

## Phase 5: User Story 3 — Attendance Saved to Database (Priority: P1)

**Goal**: Load existing attendance from the database on init, and write each new check-in to the database immediately on confirmation. Records survive page refresh.

**Independent Test**: Check in one staff member, refresh the page — the card must still show checked-in. Verify the record appears in the Supabase `attendance` table.

- [x] T017 [US3] Inside `init()`, after `currentEvent` is confirmed non-null, fetch existing attendance with `await _supabase.from('attendance').select('staff_id, checked_in_at, signature_data, id').eq('event_id', currentEvent.id)` and hydrate `attendance{}` keyed by `staff_id` — in `booth-attendance.html`
- [x] T018 [US3] Convert `confirmAttendance()` to `async function confirmAttendance()` in `booth-attendance.html`
- [x] T019 [US3] Add double-submit guard in `confirmAttendance()`: disable `#btnConfirm` before the DB insert, re-enable it only on error — in `booth-attendance.html`
- [x] T020 [US3] Replace the in-memory `attendance[currentStaffId] = {...}` assignment in `confirmAttendance()` with an `await _supabase.from('attendance').insert({staff_id, event_id, signature_data}).select('id, checked_in_at').single()` call; on success populate `attendance{}` using the server `checked_in_at` timestamp; on error show error toast and return without updating state — in `booth-attendance.html`

**Checkpoint**: Check-ins persist across page refreshes. DB-loaded attendance renders correctly on page open. Error toast shown if save fails.

---

## Phase 6: User Story 4 — Stats Bar Reflects Live Attendance (Priority: P2)

**Goal**: Ensure the stats bar counts are accurate from the first page load, reflecting DB-stored check-ins, not just in-session ones.

**Independent Test**: Pre-populate 2 attendance records in the DB via SQL Editor, open the page, and verify the stats bar shows "الحضور: 2" without making any new check-ins.

- [x] T021 [US4] Confirm `updateStats()` call in `init()` comes after `attendance{}` is fully hydrated from the DB (after T017 completes) — reorder call if needed in `booth-attendance.html`

**Checkpoint**: Stats bar shows correct counts immediately on page load based on DB records.

---

## Phase 7: User Story 5 — Export Includes Database Records (Priority: P3)

**Goal**: The export report uses the event name from the database and includes all check-ins captured across page sessions.

**Independent Test**: Record 2 check-ins, refresh the page (clearing in-memory state), then export — the report must include both check-ins with correct timestamps.

- [x] T022 [US5] Update `exportData()` in `booth-attendance.html`: replace the hardcoded `'📋 تقرير حضور البوث'` title with `'📋 تقرير حضور: ' + (currentEvent ? currentEvent.name : 'غير محدد')`
- [x] T023 [US5] Add a guard in `exportData()` in `booth-attendance.html`: if `currentEvent === null`, call `showToast('لا يوجد حدث نشط للتصدير')` and return early

**Checkpoint**: Exported report includes event name and all DB-persisted check-ins.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Code clarity, reset scoping, and end-to-end validation.

- [x] T024 [P] Add a comment above `resetAll()` in `booth-attendance.html` explicitly stating: "// Clears in-memory attendance state only — does NOT delete records from the database"
- [x] T025 [P] Add brief inline comments to the `init()` async flow in `booth-attendance.html` marking the three stages: "// 1. Fetch staff + event in parallel", "// 2. Fetch existing attendance for active event", "// 3. Render UI"
- [x] T026 Follow `specs/002-attendance-page-db/quickstart.md` Steps 1–8 to validate the complete implementation end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundation)
                        ├──► US1 Staff (Phase 3) ────────────────────────┐
                        └──► US2 Event (Phase 4) ─► US3 Attendance (Phase 5) ─► US4 Stats (Phase 6) ─► US5 Export (Phase 7) ─► Polish
```

- **Setup (Phase 1)**: Start immediately — adds script tags to `<head>`
- **Foundational (Phase 2)**: Depends on Phase 1 — adds client init, helpers, loading overlay
- **US1 Staff (Phase 3)**: Depends on Phase 2 — first part of `init()` rewrite
- **US2 Event (Phase 4)**: Depends on Phase 3 — continues `init()` rewrite; needs STAFF already handled
- **US3 Attendance (Phase 5)**: Depends on US1 + US2 — needs `currentEvent.id` to query attendance
- **US4 Stats (Phase 6)**: Depends on US3 — stats are only correct after attendance is hydrated
- **US5 Export (Phase 7)**: Depends on US2 (event name) + US3 (attendance state)
- **Polish (Phase 8)**: Depends on all stories complete

### Within Each Phase

- T006 and T007 (Phase 2) can run in parallel — different functions, no dependency
- T022 and T023 (Phase 7) can run in parallel — different parts of `exportData()`
- T024 and T025 (Phase 8) can run in parallel — different comments, no dependency

### Parallel Opportunities

- T006 + T007: `showError()` and `showFatalError()` are independent functions
- T022 + T023: Export title update and export guard are both inside `exportData()`
- T024 + T025: Comments in different functions

---

## Parallel Example: Phase 2 Foundation

```
# T005, T006, T007 can be written simultaneously (different function bodies):
Task T005: Write showLoading() function in booth-attendance.html
Task T006: Write showError() function in booth-attendance.html    ← parallel
Task T007: Write showFatalError() function in booth-attendance.html ← parallel

# T008 and T009 can be done simultaneously (HTML vs CSS sections):
Task T008: Add loadingOverlay div to HTML in booth-attendance.html
Task T009: Add .loading-overlay CSS rule in booth-attendance.html  ← parallel
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T009)
3. Complete Phase 3: US1 — Staff loads from DB (T010–T013)
4. Complete Phase 4: US2 — Active event loads (T014–T016)
5. **STOP and VALIDATE**: Staff grid shows DB data, event name in header, no-event state works
6. This alone is a working DB-connected attendance page (minus persistence)

### Incremental Delivery

1. Setup + Foundation → client initialized, helpers ready
2. US1 + US2 (Phases 3 + 4) → page loads live data ✓
3. US3 (Phase 5) → check-ins persist across refreshes ✓ ← key milestone
4. US4 (Phase 6) → stats correct from first load ✓
5. US5 (Phase 7) → export includes all DB records ✓
6. Polish (Phase 8) → code documented, end-to-end validated ✓

---

## Notes

- All tasks modify only `booth-attendance.html` — no new files
- US1 and US2 both feed into the same `init()` function; implement them as sequential sections within `init()`, not as separate functions
- The `attendance{}` object remains keyed by staff UUID string (not integer) — this is a clean break, no migration needed since `STAFF` is now loaded from DB
- `resetAll()` intentionally does NOT delete DB records — this is by design (admin reset is Phase 4)
- The `.hidden` CSS class already exists in `booth-attendance.html` (used by `sigPlaceholder`) — reuse it for the loading overlay
