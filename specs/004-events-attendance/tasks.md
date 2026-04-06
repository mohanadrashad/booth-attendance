# Tasks: Phase 4 — Events & Attendance Overview

**Input**: Design documents from `/specs/004-events-attendance/`  
**Branch**: `004-events-attendance`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: No test tasks generated — manual verification via quickstart.md.

**Organization**: All implementation is in `dashboard.html` plus two new migration files. Tasks build incrementally — tab nav first, then Events section, then Attendance section.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (independent sections, no shared logic dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)

---

## Phase 1: Setup

**Purpose**: Create the two migration files and apply them to Supabase before any code changes.

- [X] T001 Create `supabase/migrations/002_events_start_time.sql` with `ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT NULL;`
- [X] T002 [P] Create `supabase/migrations/003_events_dashboard_rls.sql` with three policies: `CREATE POLICY "anon can insert events" ON events FOR INSERT TO anon WITH CHECK (true);`, `CREATE POLICY "anon can update events" ON events FOR UPDATE TO anon USING (true) WITH CHECK (true);`, `CREATE POLICY "anon can delete events" ON events FOR DELETE TO anon USING (true);`
- [ ] T003 Apply `supabase/migrations/002_events_start_time.sql` in the Supabase SQL Editor (manual step)
- [ ] T004 Apply `supabase/migrations/003_events_dashboard_rls.sql` in the Supabase SQL Editor (manual step)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add tab navigation infrastructure and new state variables to `dashboard.html`. All user story sections depend on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 Add CSS for tab navigation to `dashboard.html`: `.tab-bar` (flex row, border-bottom, background var(--card)), `.tab-btn` (flex-1, padding, no border, Tajawal font, color var(--text-muted), cursor pointer), `.tab-btn.active` (color var(--accent), border-bottom 2px solid var(--accent))
- [X] T006 Add CSS for events section to `dashboard.html`: `.event-card` (similar to `.staff-card` but with a date sub-line), `.event-card.active-event` (accent border-right 4px), `.event-status` badge (active/inactive), event card action buttons using existing `.btn-icon` and `.card-actions` classes
- [X] T007 [P] Add CSS for attendance section to `dashboard.html`: `.attendance-table` (width 100%, border-collapse, font Tajawal), `.attendance-table th` (text-align right, padding, color var(--text-muted), font-size 12px, border-bottom), `.attendance-table td` (padding, border-bottom 1px solid var(--card-border)), `.late-badge` (background danger glow, color var(--danger), font-size 11px, padding 2px 8px, border-radius 10px), `.stats-row` (flex, gap, padding, background var(--card), border-bottom)
- [X] T008 Add HTML tab bar to `dashboard.html` just below the `.header` div: `<div class="tab-bar"><button class="tab-btn active" data-tab="staff" onclick="switchTab('staff')">الموظفون</button><button class="tab-btn" data-tab="events" onclick="switchTab('events')">الفعاليات</button><button class="tab-btn" data-tab="attendance" onclick="switchTab('attendance')">الحضور</button></div>`
- [X] T009 Wrap the existing staff section HTML (toolbar + staffList) in `<div id="section-staff" class="tab-section"></div>` in `dashboard.html`
- [X] T010 Add `<div id="section-events" class="tab-section hidden"></div>` placeholder and `<div id="section-attendance" class="tab-section hidden"></div>` placeholder after `#section-staff` in `dashboard.html`
- [X] T011 Add new state variables to the script block of `dashboard.html`: `let EVENTS = [];`, `let selectedEventId = null;`, `let ATTENDANCE = [];`, `let attendanceSearch = '';`, `let eventModalMode = null;`, `let editEventId = null;`, `let deleteConfirmEventId = null;`
- [X] T012 Add `switchTab(tab)` function to `dashboard.html`: hides all `.tab-section` elements, shows `#section-{tab}`, updates `.tab-btn` active class, calls `loadEvents()` if tab=`'events'`, calls `loadAttendance()` if tab=`'attendance'`

**Checkpoint**: Open `dashboard.html`, unlock with PIN — three tabs visible. Clicking "الفعاليات" and "الحضور" shows their (empty) sections. Clicking "الموظفون" restores the staff list.

---

## Phase 3: User Story 1 — Create Event (Priority: P1) 🎯 MVP

**Goal**: Admin can create a new event with a name, date, and optional start time. New event appears in the events list immediately.

**Independent Test**: Click "الفعاليات" tab → click "إنشاء فعالية" → submit empty → validation error. Enter name + date + start time `09:00` → submit → event appears in list. Verify in Supabase SQL Editor: `SELECT name, event_date, start_time FROM events ORDER BY created_at DESC LIMIT 1;`

- [X] T013 [US1] Build the Events section HTML inside `#section-events` in `dashboard.html`: a toolbar with `<button onclick="openEventModal('add')">إنشاء فعالية ＋</button>`, and a `<div id="eventsList"></div>` container
- [X] T014 [US1] Add `#eventModal` overlay HTML to `dashboard.html` (after `#staffModal`): `.modal-overlay` with `.modal` containing `<h2 id="eventModalTitle">`, `<input id="eventNameInput" placeholder="اسم الفعالية">`, `<input id="eventDateInput" type="date">`, `<input id="eventStartTimeInput" type="time" placeholder="وقت البدء (اختياري)">`, `<div id="eventModalError" class="modal-error hidden">`, save and cancel buttons (`onclick="submitEventModal()"` / `onclick="closeEventModal()"`)
- [X] T015 [US1] Add `async loadEvents()` function to `dashboard.html`: fetch `SELECT id, name, event_date, is_active, start_time FROM events ORDER BY event_date DESC`, assign to `EVENTS`, call `renderEventsList()`; show error state in `#eventsList` on failure
- [X] T016 [US1] Add `renderEventsList()` function to `dashboard.html`: iterate `EVENTS[]`, render each as `.event-card` showing name, formatted date, active/inactive badge, and action buttons (Edit, Activate if not active, Delete); show empty state if `EVENTS` is empty; inline delete confirm row when `deleteConfirmEventId` matches
- [X] T017 [US1] Add `openEventModal(mode, event)` and `closeEventModal()` functions to `dashboard.html` following the same pattern as `openStaffModal`/`closeStaffModal` — set `eventModalMode`, `editEventId`, pre-fill inputs, toggle `#eventModal.active`
- [X] T018 [US1] Add `async submitEventModal()` to `dashboard.html` for the **add** case: validate name + date not empty; INSERT `{name, event_date, start_time||null}` into `events` RETURNING `*`; push to `EVENTS[]`, sort by `event_date DESC`, `closeEventModal()`, `renderEventsList()`, `showToast('تمت إضافة الفعالية ✓')`; on error show `#eventModalError`

**Checkpoint**: Create event flow works end-to-end. Validation prevents empty saves. New event appears in list and in DB.

---

## Phase 4: User Story 2 — Switch Active Event (Priority: P1)

**Goal**: Admin can activate any event with one click. Exactly one event is active at any time. Attendance page reflects the switch.

**Independent Test**: With two events, click "تفعيل" on the inactive event → it becomes active (badge turns green), previous active becomes inactive. Refresh `booth-attendance.html` → header shows new event name.

- [X] T019 [US2] Add `async activateEvent(eventId)` function to `dashboard.html`: `UPDATE events SET is_active=false WHERE is_active=true`, then `UPDATE events SET is_active=true WHERE id=eventId`; update `EVENTS[]` in memory (set all false, set target true); call `renderEventsList()`; call `showToast('تم تفعيل الفعالية ✓')`; add `onclick="activateEvent('${s.id}')"` to the Activate button in `renderEventsList()`

**Checkpoint**: One-click activation works. Events list reflects the change immediately. Attendance page shows new event name after refresh.

---

## Phase 5: User Story 3 — Attendance Table (Priority: P1)

**Goal**: Admin can view all check-in records for any event in a table with staff name and time. Can filter by event and search by name.

**Independent Test**: Switch to "الحضور" tab → attendance table shows records for the active event. Use event selector to pick a different event → table updates. Type a staff name in search → rows filter. Select an empty event → empty state shown.

- [X] T020 [US3] Build the Attendance section HTML inside `#section-attendance` in `dashboard.html`: a stats row `<div id="attendanceStats">` for counts, a filter row with `<select id="eventSelector">` and `<input id="attendanceSearchInput" type="text" placeholder="بحث بالاسم...">`, and a `<div id="attendanceTableContainer">` for the table
- [X] T021 [US3] Add `async loadAttendance()` function to `dashboard.html`: set `selectedEventId` to the active event ID from `EVENTS[]` if not already set; show loading state; fetch `.from('attendance').select('id, checked_in_at, staff:staff_id(name)').eq('event_id', selectedEventId).order('checked_in_at').limit(200)`; assign to `ATTENDANCE`; call `renderAttendanceTable()`; call `renderAttendanceStats()`
- [X] T022 [US3] Add `renderAttendanceTable()` function to `dashboard.html`: filter `ATTENDANCE` by `attendanceSearch`; render `<table class="attendance-table">` with `<thead>` (الاسم, وقت الحضور columns) and `<tbody>` rows; add `isLate()` check for each row; show empty state div if no rows; show note if `ATTENDANCE.length === 200`
- [X] T023 [US3] Add `isLate(checkedInAt, startTime)` pure function to `dashboard.html`: returns `false` if `startTime` is null; parses HH:MM from `startTime`; creates a Date from `checkedInAt`; sets hours/minutes on a copy to the start time; returns `checkedInAt > startCopy` (see research.md Section 5 for exact implementation)
- [X] T024 [US3] Populate `#eventSelector` inside `loadAttendance()` in `dashboard.html`: clear and re-render `<option>` elements from `EVENTS[]` (show all events, label active one with "●"); set selected value to `selectedEventId`; wire `#eventSelector` `change` event to `selectedEventId = e.target.value; loadAttendance()`
- [X] T025 [US3] Wire `#attendanceSearchInput` `input` event in `dashboard.html` (inside `init()` event wiring block): `attendanceSearch = e.target.value.trim(); renderAttendanceTable()`

**Checkpoint**: Attendance table loads for active event. Event selector switches data. Name search filters rows. Late badge shows correctly.

---

## Phase 6: User Story 4 — Late Arrival Flags (Priority: P2)

**Goal**: Rows in the attendance table show a "متأخر" badge when `checked_in_at` is after the event's `start_time`.

**Independent Test**: Edit the active event to set `start_time = 09:00`. Find a check-in after 09:00 in the table → it should show "متأخر". Find one before 09:00 → no badge. Remove `start_time` → no badges appear at all.

- [X] T026 [US4] Verify `isLate()` is called correctly in `renderAttendanceTable()` in `dashboard.html`: look up `selectedEvent = EVENTS.find(e => e.id === selectedEventId)`; pass `record.checked_in_at` and `selectedEvent?.start_time` to `isLate()`; if `true`, append `<span class="late-badge">متأخر</span>` in the time cell of that row

**Note**: This task verifies the integration of `isLate()` (created in T023) with the table renderer (created in T022). If T022 and T023 were implemented correctly with the late badge already wired, this task is a verification/fix pass only.

**Checkpoint**: Late flags display correctly based on event start_time. Events without start_time show no flags.

---

## Phase 7: User Story 5 — Attendance Rate Stats (Priority: P2)

**Goal**: Stats bar above the attendance table shows total/present/absent/percentage for the selected event.

**Independent Test**: With 5 active staff and 3 checked in for the active event, verify stats show "الإجمالي: 5 | الحضور: 3 | الغياب: 2 | النسبة: 60%". Check in a fourth on the attendance page, reload the Attendance tab → stats update.

- [X] T027 [US5] Add `renderAttendanceStats()` function to `dashboard.html`: compute `total = STAFF.filter(s=>s.is_active).length`; `present = ATTENDANCE.length`; `absent = total - present`; `rate = total === 0 ? 0 : Math.round(present/total*100)`; render these values into `#attendanceStats` as four labelled stat blocks (الإجمالي, الحضور, الغياب, نسبة الحضور%)
- [X] T028 [US5] Ensure `renderAttendanceStats()` is called from `loadAttendance()` in `dashboard.html` after `ATTENDANCE` is populated (verify call order; add call if missing)

**Checkpoint**: Stats are accurate on load and update correctly when a different event is selected.

---

## Phase 8: Edit Event & Delete Event (US1 extensions)

**Purpose**: Complete the event CRUD — edit name/date/start_time and conditional delete.

- [X] T029 [US1] Extend `async submitEventModal()` in `dashboard.html` with the **edit** case: `UPDATE events SET name, event_date, start_time WHERE id=editEventId RETURNING *`; find and replace entry in `EVENTS[]`; `closeEventModal()`; `renderEventsList()`; `showToast('تم تحديث الفعالية ✓')`
- [X] T030 [US1] Add `async deleteEvent(eventId)` function to `dashboard.html`: count attendance records for this event using `{ count: 'exact', head: true }`; if `count > 0` call `showToast('❌ لا يمكن حذف فعالية لها سجلات حضور', true)` and return; else set `deleteConfirmEventId = eventId` and call `renderEventsList()` to show inline confirm row
- [X] T031 [US1] Add `async confirmDeleteEvent(eventId)` and `cancelDeleteEvent()` functions to `dashboard.html`: confirm → `DELETE FROM events WHERE id=eventId`; remove from `EVENTS[]`; `deleteConfirmEventId = null`; `renderEventsList()`; `showToast('تم حذف الفعالية ✓')`; cancel → `deleteConfirmEventId = null`; `renderEventsList()`
- [X] T032 [US1] Wire edit button in `renderEventsList()` in `dashboard.html` to call `openEventModal('edit', event)` with the full event object; wire delete button to call `deleteEvent(event.id)`; wire inline confirm/cancel buttons to `confirmDeleteEvent(event.id)` / `cancelDeleteEvent()`

**Checkpoint**: Edit pre-fills form and saves changes. Delete blocked if records exist. Empty-event delete works with confirmation.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T033 [P] Add `loadEvents()` call inside `loadStaff()` in `dashboard.html` (or inside `showDashboard()`) so `EVENTS[]` is pre-populated when the user first opens the Attendance tab — avoids a flash of "no events" in the event selector
- [X] T034 [P] Update `loadAttendance()` in `dashboard.html` to fall back gracefully when `EVENTS[]` is empty: show "لا توجد فعاليات — أنشئ فعالية أولاً" in `#attendanceTableContainer` and return early
- [ ] T035 Follow `specs/004-events-attendance/quickstart.md` Steps 1–10 to validate the complete implementation end-to-end

---

## Dependencies & Execution Order

```
Phase 1 (Setup: migrations) → Phase 2 (Foundation: tabs + state)
                                      ↓
                       Phase 3: US1 Create Event (P1) 🎯
                                      ↓
                       Phase 4: US2 Activate Event (P1)
                                      ↓
                       Phase 5: US3 Attendance Table (P1)
                            ↓               ↓
               Phase 6: US4 Late Flags   Phase 7: US5 Stats
               (P2) — verify T022+T023   (P2) — adds T027-T028
                            ↓               ↓
                       Phase 8: Edit + Delete Event (US1 ext)
                                      ↓
                              Phase 9: Polish
```

- **Setup (Phase 1)**: Start immediately — T001 + T002 parallel, then T003 + T004 manual
- **Foundation (Phase 2)**: Depends on Phase 1 — adds tabs, state vars, switchTab()
- **US1 Create Event (Phase 3)**: Depends on Phase 2 — Events section HTML + loadEvents + submitEventModal (add)
- **US2 Activate Event (Phase 4)**: Depends on Phase 3 — activateEvent() function
- **US3 Attendance Table (Phase 5)**: Depends on Phase 4 — needs EVENTS[] populated for event selector
- **US4 Late Flags (Phase 6)** and **US5 Stats (Phase 7)**: Both depend on Phase 5; can run in parallel
- **Phase 8 (Edit + Delete)**: Depends on Phase 3 (extends submitEventModal); can overlap with Phases 6+7
- **Polish (Phase 9)**: Depends on all phases complete

### Parallel Opportunities

- T001 + T002: Different migration files
- T005, T006, T007: Different CSS blocks in `dashboard.html`
- T009 + T010: Different HTML sections
- Phase 6 + Phase 7: Different functions, no shared dependency
- Phase 8 + Phase 6/7: Different functions
- T033 + T034: Different functions in Polish

---

## Implementation Strategy

### MVP Scope: Phases 1–5 (T001–T025)

This gives:
- Two new migration files applied
- Tab navigation working
- Full Events section: create event + activate event
- Attendance table: per-event data, event selector, search

### Incremental Delivery

1. Phases 1+2: Migrations + tab nav → foundation ready ✓
2. Phase 3 (US1): Create events → events list working ✓
3. Phase 4 (US2): Activate events → attendance page reflects switch ✓ ← **MVP**
4. Phase 5 (US3): Attendance table + search → data visibility ✓
5. Phase 6 (US4): Late flags → punctuality insight ✓
6. Phase 7 (US5): Stats → summary view ✓
7. Phase 8: Edit + delete events → full CRUD ✓
8. Phase 9: Polish → edge cases, end-to-end validation ✓

---

## Notes

- All tasks modify only `dashboard.html` (except the two migration files)
- `STAFF[]` is already loaded from Phase 3 — reused in `renderAttendanceStats()` for denominator
- `isLate()` must handle the nullable `start_time` correctly — `null` → always returns `false`
- The tab bar replaces the single-section dashboard layout; existing Staff section must be wrapped in `#section-staff` before adding the other sections
- The `deleteConfirmEventId` pattern mirrors `deleteConfirmId` from Phase 3 — same inline confirm UX
- Phase 8 (edit + delete) extends `submitEventModal()` and `renderEventsList()` which were created in Phase 3 — these tasks must run after Phase 3
