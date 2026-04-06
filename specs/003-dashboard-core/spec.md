# Feature Specification: Phase 3 — Dashboard Core

**Feature Branch**: `003-dashboard-core`  
**Created**: 2026-04-05  
**Status**: Draft

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — PIN Gate Protects the Dashboard (Priority: P1)

An admin navigates to the dashboard page. Before seeing any data, they are presented with a PIN entry screen. They type their 4-digit PIN and confirm. If the PIN is correct, they are granted access to the dashboard for the rest of the session. If the PIN is wrong, they see an error and the screen stays locked.

**Why this priority**: Every other dashboard story depends on this gate. No staff CRUD or management is accessible without authentication. This is the security boundary for the entire admin section.

**Independent Test**: Open `dashboard.html` directly — the staff management area must not be visible. Enter the wrong PIN — access is denied with an error message. Enter the correct PIN (`1234` from seed data) — dashboard unlocks and full content is visible.

**Acceptance Scenarios**:

1. **Given** a user opens the dashboard page, **When** the page loads, **Then** only the PIN entry screen is visible — no staff data, no management controls.
2. **Given** the PIN entry screen is showing, **When** the user enters the correct PIN and confirms, **Then** the PIN screen is dismissed and the full dashboard is revealed.
3. **Given** the PIN entry screen is showing, **When** the user enters an incorrect PIN, **Then** an error message is shown, the PIN field is cleared, and the screen remains locked.
4. **Given** the user has unlocked the dashboard in their current browser session, **When** they navigate away and return to `dashboard.html`, **Then** the dashboard is accessible without re-entering the PIN (session persists until browser tab is closed).
5. **Given** the dashboard is unlocked, **When** the user clicks "تسجيل خروج" (logout), **Then** the session is cleared and the PIN screen is shown again.

**Edge Cases**:

- What if the user enters fewer than 4 digits? The confirm button should remain disabled until exactly 4 digits are entered.
- What if the user presses Enter after typing 4 digits? It should behave the same as clicking confirm.
- What if the settings row does not exist in the database? The dashboard shows a setup error explaining that seed data must be run.

---

### User Story 2 — Admin Views the Staff List (Priority: P1)

After unlocking the dashboard, the admin sees a list of all staff members — both active and soft-deleted — with each person's name and current status clearly shown. The list is searchable and filterable.

**Why this priority**: The staff list is the primary view of the dashboard. All staff management actions (add, edit, delete) operate on this list. It must load and render correctly before any management features are built.

**Independent Test**: After unlocking, verify all seeded staff members appear in the list. Verify that a soft-deleted staff member (set via SQL) appears with a visual "inactive" indicator. Verify the search box filters the list in real time.

**Acceptance Scenarios**:

1. **Given** the dashboard is unlocked, **When** the staff list loads, **Then** all staff members (active and inactive) are shown, ordered alphabetically by name.
2. **Given** a staff member has `is_active = false`, **When** the staff list renders, **Then** that person appears with a distinct visual indicator (e.g., dimmed appearance and "غير نشط" label).
3. **Given** the admin types in the search box, **When** they type part of a staff member's name, **Then** the list filters in real time to show only matching names.
4. **Given** the admin clears the search box, **When** it is empty, **Then** the full staff list is shown again.
5. **Given** no staff members exist in the database, **When** the staff list loads, **Then** an "empty state" message is shown with a prompt to add the first staff member.

---

### User Story 3 — Admin Adds a New Staff Member (Priority: P1)

The admin clicks an "إضافة موظف" (Add Staff) button, fills in the staff member's name in a modal form, and submits. The new staff member is immediately saved to the database and appears in the staff list without a page refresh.

**Why this priority**: Without the ability to add staff, the entire attendance system is limited to the seeded data. This is the most common management action an admin will perform.

**Independent Test**: Click "إضافة موظف", enter a new Arabic name, submit — verify the name appears in the staff list immediately and is present in the `staff` table in the database.

**Acceptance Scenarios**:

1. **Given** the admin clicks "إضافة موظف", **When** the modal opens, **Then** an empty name input field is shown with a submit button and a cancel button.
2. **Given** the add staff modal is open, **When** the admin enters a name and clicks submit, **Then** the new staff member is saved and appears at the correct alphabetical position in the list.
3. **Given** the add staff modal is open, **When** the admin submits an empty name, **Then** the form shows a validation error and does not save.
4. **Given** the add staff modal is open, **When** the admin clicks cancel or taps outside the modal, **Then** the modal closes without saving anything.
5. **Given** the database save fails (network error), **When** the admin submits the form, **Then** an error message is shown and the modal remains open so the admin can retry.

---

### User Story 4 — Admin Edits a Staff Member's Name (Priority: P2)

The admin clicks an edit button on a staff card, changes the name in a pre-filled modal form, and saves. The updated name is immediately reflected in the staff list.

**Why this priority**: Names may need correction after initial entry (typos, formatting). This is less critical than adding staff but required for data integrity.

**Independent Test**: Click edit on any staff card, change the name, save — verify the updated name appears in the list immediately and is updated in the database.

**Acceptance Scenarios**:

1. **Given** the admin clicks the edit icon on a staff card, **When** the edit modal opens, **Then** the current name is pre-filled in the input field.
2. **Given** the edit modal is open with a changed name, **When** the admin saves, **Then** the staff record is updated in the database and the new name appears in the list.
3. **Given** the edit modal is open, **When** the admin clears the name field and tries to save, **Then** a validation error is shown and nothing is saved.
4. **Given** the edit modal is open, **When** the admin clicks cancel, **Then** the name is not changed.

---

### User Story 5 — Admin Soft-Deletes a Staff Member (Priority: P2)

The admin clicks a delete button on a staff card. A confirmation prompt appears asking them to confirm. On confirmation, the staff member is marked as inactive in the database. The attendance page no longer shows them, but their historical attendance records are preserved.

**Why this priority**: Staff turnover is expected. Soft-delete preserves the integrity of past attendance records while removing the person from the active check-in flow.

**Independent Test**: Delete a staff member, verify they no longer appear on the attendance page, then verify their historical attendance rows still exist in the database.

**Acceptance Scenarios**:

1. **Given** the admin clicks the delete icon on an active staff card, **When** the confirmation prompt appears, **Then** the admin can confirm or cancel.
2. **Given** the admin confirms deletion, **When** the save completes, **Then** the staff member's `is_active` is set to `false` in the database and they no longer appear on the attendance page.
3. **Given** the admin confirms deletion, **When** the save completes, **Then** the staff member still appears in the dashboard staff list with an "غير نشط" indicator (soft-deleted, not erased).
4. **Given** a soft-deleted staff member's prior attendance records exist, **When** deleted, **Then** those records remain intact in the database.
5. **Given** the admin cancels the deletion confirmation, **Then** nothing changes.

---

### Edge Cases (Cross-Cutting)

- What if two admins are using the dashboard simultaneously on different devices? The last write wins; no conflict resolution is in scope for this phase.
- What if a staff member has attendance records for the current active event and is soft-deleted? The deletion still proceeds — the attendance record remains, but the card disappears from the attendance page on next load.
- What if the admin loses network connectivity mid-operation? All write operations must show clear error messages and not leave the UI in a broken state.
- What if the staff list has many members (50+)? The search box provides filtering; no pagination is required for this phase.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The dashboard (`dashboard.html`) MUST display only the PIN entry screen on initial load — no staff data or controls visible before authentication.
- **FR-002**: The PIN entry screen MUST remain disabled (confirm button grayed out) until exactly 4 digits have been entered.
- **FR-003**: The system MUST verify the entered PIN by comparing its hash against the stored hash in the database — the plain-text PIN is never stored or transmitted in plain text.
- **FR-004**: On successful PIN entry, the session MUST be stored so the user is not asked to re-enter the PIN if they navigate away and return within the same browser session.
- **FR-005**: On failed PIN entry, the system MUST display an Arabic error message, clear the PIN field, and keep the screen locked.
- **FR-006**: The dashboard MUST provide a logout control that clears the session and returns the user to the PIN screen.
- **FR-007**: After authentication, the staff list MUST load all staff members (active and inactive) from the database, ordered alphabetically.
- **FR-008**: Active and inactive staff members MUST be visually differentiated in the staff list.
- **FR-009**: The staff list MUST include a real-time search box that filters by name without requiring a page refresh or submit action.
- **FR-010**: The dashboard MUST provide an "إضافة موظف" button that opens a modal form for entering a new staff member's name.
- **FR-011**: The add staff form MUST validate that the name is not empty before allowing submission.
- **FR-012**: On successful add, the new staff member MUST appear in the list immediately without a full page refresh.
- **FR-013**: Each staff card in the list MUST have an edit control that opens a pre-filled modal form for updating the name.
- **FR-014**: On successful edit, the updated name MUST appear in the list immediately without a full page refresh.
- **FR-015**: Each staff card MUST have a delete control that triggers a confirmation prompt before soft-deleting the staff member.
- **FR-016**: Soft-delete MUST set `is_active = false` in the database; the staff member's historical attendance records MUST NOT be deleted.
- **FR-017**: After soft-deletion, the staff member MUST disappear from the attendance page on next load but remain visible in the dashboard list with an inactive indicator.
- **FR-018**: All write operations (add, edit, delete) MUST show loading feedback and display an Arabic error message on failure without breaking the UI.

### Key Entities

- **Settings** (read from DB on PIN check): Used to retrieve the stored PIN hash for verification. Attributes used: `pin_hash`.
- **Staff** (read + written): Full CRUD target. Attributes: `id`, `name`, `is_active`, `created_at`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The PIN gate correctly blocks access 100% of the time — no path to dashboard content without a valid PIN.
- **SC-002**: Incorrect PIN attempts are rejected 100% of the time with a visible error message.
- **SC-003**: The staff list loads within 2 seconds of the dashboard being unlocked on a standard broadband connection.
- **SC-004**: Adding, editing, or soft-deleting a staff member completes (including the DB write) in under 2 seconds under normal conditions.
- **SC-005**: Real-time search filters results as the admin types, with results visible within 100ms of each keystroke (client-side filtering, no network round-trip).
- **SC-006**: 100% of soft-delete operations preserve historical attendance records — zero cascading data loss.
- **SC-007**: The dashboard is fully functional on both desktop and mobile browsers (Arabic RTL layout throughout).

---

## Assumptions

- Phase 1 (database) and Phase 2 (attendance page) are complete and working.
- `dashboard.html` is a new file; the existing `booth-attendance.html` (attendance page) is not modified in this phase.
- The dashboard uses the same `config.js` credentials file as the attendance page — no separate credential file.
- The Supabase anon key is sufficient for the PIN check (SELECT on settings) and for staff writes; service-role is not required because RLS is intentionally permissive for staff writes via anon key (Phase 1 design — all admin operations run from the dashboard using the same anon key behind the PIN gate).
- Session persistence is implemented using `sessionStorage` — the PIN is not re-requested within the same browser tab session, but a new tab or browser restart requires re-authentication.
- No rate limiting on PIN attempts is implemented in this phase (the dashboard is not publicly accessible in a typical deployment scenario).
- The dashboard UI is Arabic RTL, using the same Tajawal font and dark-mode CSS variables as the attendance page.
- Staff names are free-form Arabic text; no character restrictions or uniqueness validation are enforced.
- The "add staff" flow only captures the name — no role, department, or photo fields in this phase.
- Reactivating a soft-deleted staff member (setting `is_active` back to `true`) is out of scope for this phase and will be addressed in Phase 4.
