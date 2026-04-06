# Feature Specification: Phase 4 — Events & Attendance Overview

**Feature Branch**: `004-events-attendance`  
**Created**: 2026-04-05  
**Status**: Draft

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Admin Creates a New Event (Priority: P1)

The admin opens the dashboard and navigates to an "Events" section. They click "إنشاء حدث" (Create Event), fill in a name and date, and save. The new event is added to the events list. If they choose to make it the active event, any previous active event is automatically deactivated so only one event is active at a time.

**Why this priority**: Without event management, the attendance page is locked to the single seeded event forever. This is the prerequisite for all other stories in this phase.

**Independent Test**: Create a new event named "يوم التوظيف 2026" with today's date — verify it appears in the events list. Then mark it active — verify the attendance page header shows its name on next load.

**Acceptance Scenarios**:

1. **Given** the admin is on the Events section, **When** they click "إنشاء حدث", **Then** a form opens with name and date fields.
2. **Given** the create event form is open, **When** the admin submits with a valid name and date, **Then** the event is saved and appears in the events list.
3. **Given** the create event form is open, **When** the admin submits with an empty name or no date, **Then** a validation error is shown and nothing is saved.
4. **Given** the admin creates an event and marks it active, **When** there was already an active event, **Then** the previous event is automatically set to inactive and the new one becomes active.
5. **Given** only one event can be active at a time, **When** the admin views the events list, **Then** the active event is clearly distinguished from past/inactive events.

---

### User Story 2 — Admin Switches the Active Event (Priority: P1)

The admin views the events list and can set any existing event as the active one. Switching the active event immediately changes which event the attendance page records check-ins against. The admin can also view historical events without affecting the active state.

**Why this priority**: A single booth may run multiple events across different days. The admin must be able to switch the active event before each session without deleting old data.

**Independent Test**: With two events in the database, set Event B as active — open the attendance page, verify Event B's name appears in the header. Switch back to Event A — verify Event A's name appears.

**Acceptance Scenarios**:

1. **Given** multiple events exist, **When** the admin clicks "تفعيل" (Activate) on an inactive event, **Then** that event becomes active, the previously active event becomes inactive, and the attendance page reflects the change on next load.
2. **Given** an event is currently active, **When** the admin tries to activate it again, **Then** nothing changes (it is already active; the button should be disabled or absent).
3. **Given** the admin switches the active event, **When** they return to the attendance page, **Then** staff who were checked in for the *old* event are NOT shown as checked in — the check-in state resets to the new event's actual records.

---

### User Story 3 — Admin Views the Attendance Table (Priority: P1)

The admin opens an "Attendance" section in the dashboard and sees a table of all attendance records for the currently active event: staff name, check-in time, and whether a signature was captured. The table can be filtered by event and sorted by time.

**Why this priority**: The admin needs visibility into attendance data beyond just the attendance page's card view. This is the core operational reporting view.

**Independent Test**: After recording 3 check-ins on the attendance page, open the dashboard attendance table — verify all 3 records appear with correct names and timestamps. Filter by a different (empty) event — verify the table shows zero records.

**Acceptance Scenarios**:

1. **Given** the admin is on the Attendance section, **When** the page loads, **Then** all check-in records for the currently active event are shown in a table with columns: staff name, check-in time.
2. **Given** attendance records exist for multiple events, **When** the admin selects a different event from the event filter, **Then** the table updates to show only records for the selected event.
3. **Given** the attendance table is showing, **When** no records exist for the selected event, **Then** an empty state message is displayed (not an error).
4. **Given** the admin wants to find a specific person, **When** they type in the search box above the table, **Then** the table filters to show only rows matching the typed name.

---

### User Story 4 — Admin Sees Late Arrival Flags (Priority: P2)

The attendance table marks staff members who checked in after a configurable "expected start time" for an event. Late arrivals are visually flagged so the admin can see punctuality at a glance.

**Why this priority**: Attendance tracking is more valuable when it captures not just presence but timeliness. This enriches the existing attendance records without requiring any new data from operators.

**Independent Test**: Set an event's expected start time to 09:00. Check in one staff member at 08:50 (on time) and another at 09:15 (late). Open the attendance table — verify the 09:15 check-in is flagged as late and the 08:50 one is not.

**Acceptance Scenarios**:

1. **Given** an event has an expected start time set, **When** a staff member's check-in time is after that start time, **Then** their row in the attendance table is marked with a "متأخر" (Late) indicator.
2. **Given** an event has an expected start time set, **When** a staff member checked in on or before the start time, **Then** no late indicator is shown for their row.
3. **Given** an event has no expected start time, **When** the attendance table is shown, **Then** no late flags appear (the feature is opt-in per event).
4. **Given** the admin creates or edits an event, **When** they set an expected start time, **Then** the late flag logic is applied retroactively to all existing check-ins for that event.

---

### User Story 5 — Admin Views Attendance Rate Stats (Priority: P2)

The dashboard shows summary statistics for each event: total staff invited, number present, number absent, attendance rate percentage. These stats update in real time as check-ins are recorded on the attendance page.

**Why this priority**: Managers need a quick summary without manually counting rows in the attendance table. This turns raw data into actionable insight.

**Independent Test**: With 5 staff and 3 checked in for the active event, open the dashboard — verify the stats show "الحضور: 3 / 5 (60%)". Check in a fourth staff member on the attendance page — return to the dashboard and verify the stats update.

**Acceptance Scenarios**:

1. **Given** the admin views the active event summary, **When** the data loads, **Then** they see: total active staff count, present count, absent count, and attendance rate percentage.
2. **Given** a new check-in is recorded on the attendance page, **When** the admin refreshes the dashboard or the stats auto-update, **Then** the present count and percentage reflect the new check-in.
3. **Given** the admin switches to a historical event, **When** the stats are shown, **Then** they reflect the final attendance data for that event (not the current staff roster).
4. **Given** an event has zero check-ins, **When** the stats are shown, **Then** attendance rate is shown as 0% (not an error or blank).

---

### Edge Cases

- What if an event is deleted while check-ins reference it? Deletion should be blocked if the event has attendance records — the admin must archive/deactivate rather than delete.
- What if the admin creates two events with the same name and date? Allowed — names are not required to be unique (two sessions of the same event may occur).
- What if the active event is switched while an operator is mid-check-in on the attendance page? The check-in completes against the event ID captured when the modal opened — no interruption or data loss.
- What if there are no active staff members? Stats show 0/0 with an explanatory message rather than a divide-by-zero error.
- What if the attendance table has hundreds of records? The table must remain usable — pagination or a visible row limit is acceptable.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The dashboard MUST have an Events section listing all events (active and past) with name, date, and active status.
- **FR-002**: The Events section MUST provide a "إنشاء حدث" button that opens a form with name (text, required) and date (date picker, required) fields.
- **FR-003**: The Events section MUST provide an optional "وقت البدء المتوقع" (Expected Start Time) field when creating or editing an event.
- **FR-004**: On event save, the system MUST validate that name and date are not empty and display Arabic validation errors if either is missing.
- **FR-005**: When an event is set as active, the system MUST automatically deactivate all other events so exactly one event is active at any time.
- **FR-006**: Events MUST NOT be hard-deletable if they have attendance records; the system MUST block deletion and show an explanatory message.
- **FR-007**: Events with no attendance records MAY be deleted; the admin is shown a confirmation prompt before deletion proceeds.
- **FR-008**: The dashboard MUST have an Attendance section showing a table of check-in records with columns: staff name and check-in time.
- **FR-009**: The Attendance section MUST default to showing records for the currently active event.
- **FR-010**: The Attendance section MUST provide an event selector so the admin can view records for any event.
- **FR-011**: The Attendance section MUST provide a search box that filters table rows by staff name in real time.
- **FR-012**: If an event has an expected start time, the attendance table MUST display a "متأخر" badge on rows where check-in time is after the expected start time.
- **FR-013**: The dashboard MUST display attendance rate statistics for the selected event: total staff count, present, absent, and percentage.
- **FR-014**: Attendance statistics MUST reflect only active staff members in the total count (soft-deleted staff are excluded from the denominator).
- **FR-015**: The events list and attendance statistics MUST refresh when the admin manually reloads the section; no mandatory real-time push updates are required.

### Key Entities

- **Event** (read + write): Name, date, expected start time (optional), active flag. Full CRUD in the Events section.
- **Attendance** (read-only in dashboard): Records queried per event. Joined with staff for display.
- **Staff** (read-only in dashboard stats): Active staff count used as denominator for attendance rate.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The admin can create a new event and activate it in under 30 seconds from opening the Events section.
- **SC-002**: Switching the active event takes a single click — the attendance page reflects the change within 1 page reload.
- **SC-003**: The attendance table for any event loads in under 3 seconds on a standard broadband connection.
- **SC-004**: Late arrival flags appear correctly for 100% of check-ins relative to the event's expected start time.
- **SC-005**: Attendance rate statistics are accurate to 100% — no rounding errors or stale data after a manual refresh.
- **SC-006**: Attempting to delete an event with attendance records is blocked 100% of the time — zero data loss from accidental deletion.

---

## Assumptions

- Phase 1 (database), Phase 2 (attendance page), and Phase 3 (dashboard core + PIN gate) are complete.
- The Events and Attendance sections are added as new navigation tabs or sections within the existing `dashboard.html` file — no new HTML pages are created.
- Navigation between sections (Staff, Events, Attendance) uses a tab/section switching pattern within the same page, consistent with the single-file architecture.
- The expected start time on an event is stored as a time value (HH:MM) and compared against the local time extracted from each `checked_in_at` timestamp for late flagging.
- Attendance rate denominator = count of active staff at the time of viewing (not a snapshot at event creation time), consistent with how the attendance page works.
- The attendance table shows a maximum of 200 rows without pagination; if a single event exceeds 200 check-ins, a note is shown (this scenario is unlikely given the app's scale of ~50 staff).
- Event editing (changing name, date, or start time) is in scope; only deletion is conditionally blocked.
- The "reactivate a soft-deleted staff member" feature deferred from Phase 3 is still out of scope for this phase.
- All dates and times are displayed in the user's local timezone (browser timezone); no timezone conversion UI is required.
