# Feature Specification: Export & Settings

**Feature Branch**: `005-export-settings`  
**Created**: 2026-04-05  
**Status**: Draft  
**Input**: User description: "read plan.md and create specification for next phase"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Export Attendance Report (Priority: P1)

The admin needs to share or archive attendance data after an event. They open an Export section in the dashboard, choose an event, and download the records as a text report or CSV file. Each record includes the staff member's name and check-in time. A PDF export option also produces a document that includes each staff member's captured signature alongside their record.

**Why this priority**: Attendance data has no value if it cannot leave the system. Export delivers immediate standalone value and is the most practical output of the entire tool — needed every time an event ends.

**Independent Test**: Navigate to the Export tab, select "معرض الكتاب 2026", click "تصدير CSV" — a `.csv` file downloads with one row per attendee (name, check-in time). Click "تصدير نصي" — a `.txt` file downloads with a formatted Arabic report. Verify row count matches the Attendance tab for that event.

**Acceptance Scenarios**:

1. **Given** an event with 5 check-ins, **When** the admin clicks "تصدير CSV", **Then** a file named `[event-name]-attendance.csv` downloads containing a header row and 5 data rows, each with staff name and check-in time.
2. **Given** an event with check-ins, **When** the admin clicks "تصدير نصي", **Then** a `.txt` file downloads showing the event name, date, total count, and each attendee's name and time in readable Arabic format.
3. **Given** staff signed in via the attendance page (capturing signatures), **When** the admin clicks "تصدير PDF", **Then** a PDF downloads with each attendee's name, check-in time, and their signature image.
4. **Given** an event with zero check-ins, **When** the admin attempts any export, **Then** an error message appears: "لا توجد سجلات للتصدير".
5. **Given** the admin selects a different event in the export selector, **When** the selection changes, **Then** the record count preview updates immediately to reflect the new event's data.

---

### User Story 2 — Change Dashboard PIN (Priority: P2)

The admin wants to update the 4-digit dashboard access PIN — either as routine security hygiene or because the PIN was shared. They open the Settings tab, verify their current PIN, enter and confirm a new PIN, and save. The new PIN takes effect immediately on the next login.

**Why this priority**: Without a self-service PIN change, a non-technical admin must access the database directly to update security credentials. This is a critical gap in the security model.

**Independent Test**: Go to Settings, enter current PIN `1234`, enter new PIN `5678` twice, click "حفظ". Log out. Try logging in with `1234` — fails. Log in with `5678` — succeeds.

**Acceptance Scenarios**:

1. **Given** the admin enters the correct current PIN, a valid new PIN, and a matching confirmation, **When** they click "حفظ", **Then** the PIN is updated and a success toast appears.
2. **Given** the admin enters an incorrect current PIN, **When** they submit, **Then** an error appears: "رمز PIN الحالي غير صحيح".
3. **Given** the admin enters a new PIN and a non-matching confirmation, **When** they submit, **Then** an error appears: "رمزا PIN غير متطابقَين".
4. **Given** the admin enters a new PIN fewer than 4 digits, **When** they attempt to submit, **Then** the save button remains disabled.
5. **Given** the PIN was just changed, **When** the admin logs out and logs in with the new PIN, **Then** access is granted.

---

### User Story 3 — Theme Toggle (Priority: P3)

The admin wants to switch between the existing dark theme and a light theme based on ambient lighting conditions or personal preference. The chosen theme is remembered so it persists without re-selecting on every visit.

**Why this priority**: A quality-of-life improvement. Core export and security features take precedence, but theme persistence is a common expectation for any admin tool used daily.

**Independent Test**: Open Settings, toggle to light theme — the dashboard switches to a light color scheme immediately. Refresh the page — light theme persists. Toggle back to dark — it returns.

**Acceptance Scenarios**:

1. **Given** the app is in dark mode (default), **When** the admin toggles the theme switch to light, **Then** the interface immediately switches to a light color scheme.
2. **Given** the admin switched to light mode, **When** they refresh the page or re-open the dashboard, **Then** light mode is still active.
3. **Given** the app is in light mode, **When** the admin toggles the switch again, **Then** it returns to dark mode.

---

### Edge Cases

- What if a staff member's signature is missing or empty for a PDF export row? — Show a blank signature cell for that row; do not fail the entire PDF.
- What if the browser blocks the file download (popup blocker)? — Show a message instructing the admin to allow downloads from this page.
- What if the settings row is missing from the database? — Show a clear Arabic error in the Settings panel rather than a silent failure.
- What if the admin sets the new PIN to the same value as the current PIN? — Allow it; the save succeeds silently (idempotent).
- What if `EVENTS[]` is empty when the Export tab is opened? — Show "لا توجد فعاليات — أنشئ فعالية أولاً" instead of the export controls.

## Requirements *(mandatory)*

### Functional Requirements

**Export**

- **FR-001**: The system MUST allow the admin to export attendance records for any selected event as a CSV file.
- **FR-002**: The system MUST allow the admin to export attendance records for any selected event as a plain-text report.
- **FR-003**: The system MUST allow the admin to export attendance records for any selected event as a PDF that embeds each staff member's captured signature.
- **FR-004**: The admin MUST be able to select which event to export before downloading any file.
- **FR-005**: The system MUST display the record count for the selected event before the admin initiates the export.
- **FR-006**: The system MUST block all export actions and show an Arabic error when the selected event has zero attendance records.
- **FR-007**: Downloaded files MUST be named using the event name (e.g., `[event-name]-attendance.csv`).

**Settings — PIN Change**

- **FR-008**: The system MUST require entry of the current PIN before accepting a PIN change.
- **FR-009**: The system MUST require the new PIN to be entered twice and validate the two entries match.
- **FR-010**: The system MUST enforce that any new PIN is exactly 4 numeric digits; the save button MUST remain disabled otherwise.
- **FR-011**: Upon successful PIN change, the new PIN MUST take effect immediately for the next login.

**Settings — Theme**

- **FR-012**: The system MUST provide a toggle to switch between dark and light themes.
- **FR-013**: The selected theme MUST persist across page refreshes and browser sessions without requiring re-selection.

### Key Entities

- **Attendance Record**: A check-in entry containing a staff member's name, timestamp, and signature image. The source data for all export formats.
- **Settings**: A single configuration row storing the hashed dashboard PIN and user preferences (theme choice). Updated by the PIN change flow.
- **Export File**: A transient file (CSV, TXT, or PDF) generated on demand in the browser from attendance records for a specific event.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The admin can produce a complete attendance export for any event in under 10 seconds for up to 200 records.
- **SC-002**: All three export formats (CSV, text, PDF) produce files where zero records are lost or corrupted relative to the data shown in the Attendance tab.
- **SC-003**: The PIN change flow completes in under 30 seconds and the new PIN works on the very next login.
- **SC-004**: The selected theme persists across 100% of page refreshes without requiring re-selection.
- **SC-005**: Export is blocked with a visible Arabic error message when no records exist — zero silent failures or empty file downloads.

## Assumptions

- Signatures are stored as base64 image strings in the `attendance` table (established in Phase 1 schema). PDF export reads directly from this column.
- If a record's signature value is null or empty, the PDF shows a blank cell for that row rather than failing.
- The light theme uses identical layout and components as the dark theme — only color values differ (CSS variable overrides).
- Language toggle (Arabic ↔ English) is out of scope for this phase. The app remains Arabic-only. Full translation of all UI strings is a separate, larger effort.
- The admin must already be authenticated (past the PIN screen) to access both the Export tab and the Settings tab.
- All file generation happens client-side in the browser — no server-side processing or file storage is needed.
- The export event selector reuses `EVENTS[]` already loaded in the dashboard — no additional database fetch is required for event listing.
- Theme preference is stored locally in the browser (not in the database) — it is per-device, not synced across devices.
