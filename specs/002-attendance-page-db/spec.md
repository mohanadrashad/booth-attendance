# Feature Specification: Phase 2 — Attendance Page (DB Connected)

**Feature Branch**: `002-attendance-page-db`  
**Created**: 2026-04-05  
**Status**: Draft  
**Input**: User description: "Phase 2 - Attendance Page DB Connected"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Staff Grid Loads from Database (Priority: P1)

A booth operator opens the attendance page and sees the full list of active staff members loaded from the database — not a hardcoded list. The page shows each staff member as a card that can be tapped to record attendance.

**Why this priority**: This is the entry point for every check-in. Nothing else works until the staff list loads correctly. Replacing the hardcoded staff array with a live database query is the foundational change of this entire phase.

**Independent Test**: Can be fully tested by opening the attendance page, verifying the staff cards match the seeded database records, then adding a new staff member in the database and confirming it appears on next page load.

**Acceptance Scenarios**:

1. **Given** the database has 5 active staff members, **When** the attendance page loads, **Then** exactly 5 staff cards are displayed with the correct names.
2. **Given** a staff member has `is_active = false`, **When** the attendance page loads, **Then** that staff member does not appear in the grid.
3. **Given** the database is unreachable, **When** the page loads, **Then** a clear Arabic error message is shown instead of a blank or broken grid.
4. **Given** the database returns zero active staff, **When** the page loads, **Then** an "no active staff" message is displayed rather than an empty grid.

---

### User Story 2 - Active Event Loads and Displays (Priority: P1)

The attendance page reads the currently active event from the database and displays its name at the top of the page, so the booth operator knows which event they are recording attendance for.

**Why this priority**: Without knowing the active event, the page cannot associate check-ins with the correct event. This must work before any attendance can be recorded.

**Independent Test**: Can be fully tested by verifying the event name shown on the page matches the active event in the database, and by testing the no-active-event state blocks check-ins.

**Acceptance Scenarios**:

1. **Given** one event has `is_active = true`, **When** the page loads, **Then** the event name and date are displayed in the page header.
2. **Given** no event has `is_active = true`, **When** the page loads, **Then** the check-in functionality is disabled and a message explains that no active event is set.
3. **Given** the active event changes in the database, **When** the page is refreshed, **Then** the new active event name is shown.

---

### User Story 3 - Attendance is Saved to Database (Priority: P1)

A booth operator taps a staff card, draws a signature in the modal, and confirms. The attendance record — including the signature — is saved to the database in real time, linked to the correct staff member and active event.

**Why this priority**: This is the primary action the entire app exists to perform. A successfully recorded check-in must survive a page refresh, proving it is persisted and not just held in memory.

**Independent Test**: Can be fully tested by checking in a staff member, refreshing the page, and confirming the card still shows as checked in (because the state is loaded from the database, not memory).

**Acceptance Scenarios**:

1. **Given** a staff member is not yet checked in, **When** the operator draws a signature and confirms, **Then** an attendance record is created in the database with the staff ID, event ID, timestamp, and signature data.
2. **Given** an attendance record was saved, **When** the page is refreshed, **Then** the checked-in staff card is shown in its checked-in state (not reset to unchecked).
3. **Given** a staff member is already checked in, **When** the page loads their record from the database, **Then** their card is non-interactive (pointer-events disabled) so they cannot be checked in twice.
4. **Given** the database write fails (network error), **When** the operator confirms, **Then** an error message is shown and the card does not appear as checked in.

---

### User Story 4 - Stats Bar Reflects Live Attendance (Priority: P2)

The stats bar at the top of the page shows the correct present and absent counts based on attendance records loaded from the database, not from in-memory state.

**Why this priority**: Stats must reflect real data. If the page is opened mid-event after some check-ins have already happened, the stats must show those prior check-ins, not start from zero.

**Independent Test**: Can be fully tested by pre-populating the database with some attendance records for the active event, opening the page, and verifying the present count matches without any new check-ins.

**Acceptance Scenarios**:

1. **Given** 3 of 5 staff members are already checked in (from database), **When** the page loads, **Then** the stats bar shows "Present: 3 / Absent: 2".
2. **Given** a new check-in is completed, **When** the confirmation succeeds, **Then** the stats bar updates immediately to reflect the new count without a page refresh.

---

### User Story 5 - Export Includes Database Records (Priority: P3)

The export function generates a report from attendance records stored in the database for the active event, not from in-memory state, so the exported data is complete even if the page was refreshed during the session.

**Why this priority**: Export is only useful if it reflects all check-ins for the event, including those captured in earlier page sessions. This depends on US3 (DB persistence) being complete.

**Independent Test**: Can be fully tested by recording some check-ins, refreshing the page (clearing all in-memory state), then exporting and verifying the exported report includes all prior check-ins.

**Acceptance Scenarios**:

1. **Given** 4 staff members are checked in across two page sessions, **When** the export button is tapped, **Then** the exported report lists all 4 check-ins with their timestamps.
2. **Given** no staff are checked in for the active event, **When** export is tapped, **Then** the export shows an empty attendance report (not an error).

---

### Edge Cases

- What happens when the network drops mid-signature (after drawing but before confirming)? The operator should still be able to attempt submission; the error appears on confirm.
- What happens if two devices are used simultaneously and the same staff member is checked in from both? The second insert hits the `UNIQUE(staff_id, event_id)` constraint — the second device shows an error and the check-in is not duplicated.
- What happens when the attendance page loads slowly (database query takes time)? A loading state must be shown so the operator doesn't think the page is broken.
- What happens if `config.js` is missing or has incorrect credentials? The page must show a clear setup error rather than an uncaught exception.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST load the list of active staff members from persistent storage on page load, replacing the hardcoded staff array.
- **FR-002**: The system MUST display a loading indicator while staff and event data are being fetched.
- **FR-003**: The system MUST load the currently active event from persistent storage and display its name and date in the page header.
- **FR-004**: The system MUST disable all check-in functionality and display an explanatory message if no active event exists.
- **FR-005**: The system MUST load all existing attendance records for the active event on page load and reflect them in the staff card states.
- **FR-006**: The system MUST save each confirmed attendance record — including staff ID, event ID, timestamp, and signature data — to persistent storage immediately on confirmation.
- **FR-007**: The system MUST display a success toast confirmation after a check-in is successfully saved.
- **FR-008**: The system MUST display an error message (in Arabic) if a check-in save fails, without marking the card as checked in.
- **FR-009**: The system MUST show a checked-in state for any staff member whose attendance record already exists in the database for the active event, including records from previous page sessions.
- **FR-010**: The system MUST prevent re-checking-in a staff member who already has an attendance record for the active event (card must be non-interactive).
- **FR-011**: The stats bar MUST reflect the present and absent counts based on database records, updated immediately after each new check-in.
- **FR-012**: The export function MUST generate the attendance report from database records for the active event, not from in-memory state.
- **FR-013**: The system MUST display a clear Arabic error message if the data store is unreachable at page load, without showing a blank or broken UI.
- **FR-014**: The system MUST display a clear error if credentials are missing or invalid, guiding the operator to check the configuration.

### Key Entities

- **Staff** (read from DB): Active staff members displayed as cards. Attributes used: `id`, `name`, `is_active`.
- **Event** (read from DB): Active event displayed in header, used to scope all attendance queries and inserts. Attributes used: `id`, `name`, `event_date`, `is_active`.
- **Attendance** (read + written to DB): Records of check-ins for the active event. Attributes used: `id`, `staff_id`, `event_id`, `checked_in_at`, `signature_data`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The attendance page fully loads (staff grid visible, event name shown) in under 3 seconds on a standard broadband connection.
- **SC-002**: A check-in confirmation (signature drawn → confirm tapped → record saved) completes in under 2 seconds under normal network conditions.
- **SC-003**: 100% of confirmed check-ins survive a page refresh — no attendance data is lost due to in-memory state reset.
- **SC-004**: The staff grid accurately reflects the database state on every page load — zero discrepancy between displayed cards and database records.
- **SC-005**: 100% of duplicate check-in attempts are silently blocked — the card remains non-interactive and no duplicate record is created.
- **SC-006**: The exported report includes 100% of attendance records for the active event, including those recorded in prior page sessions.

## Assumptions

- Phase 1 (database setup) is complete: all four tables exist, RLS policies are active, and seed data is in place.
- The `config.js` file is present in the project root with valid Supabase credentials before the attendance page is opened.
- The Supabase JS client library is loaded from CDN in the HTML file (no build step or local install).
- The reset button clears in-memory UI state only; it does not delete records from the database (resetting DB records is an admin function, deferred to Phase 3/4).
- The attendance page is used on a single shared device per event session (no real-time multi-device sync required in this phase).
- Signature data is stored as a base64-encoded PNG string, consistent with Phase 1 schema.
- The page UI language remains Arabic (RTL); no localisation changes are in scope for this phase.
- The existing CSS and HTML structure of `booth-attendance.html` is preserved; only the JavaScript data layer is replaced.
