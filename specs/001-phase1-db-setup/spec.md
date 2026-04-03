# Feature Specification: Phase 1 — Data Foundation

**Feature Branch**: `001-phase1-db-setup`  
**Created**: 2026-04-03  
**Status**: Draft  
**Input**: User description: "Phase 1 - Database Setup"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Application Can Store and Retrieve Staff Data (Priority: P1)

A developer sets up the data store so that the attendance application can load a list of staff members, display them to the booth operator, and persist any changes (additions, edits, deactivations) made by an admin.

**Why this priority**: All other features depend on staff records existing in persistent storage. Without this, no attendance can be recorded, no dashboard can manage staff, and no exports are possible. This is the foundational dependency.

**Independent Test**: Can be fully tested by verifying that staff records can be created, read, updated (including soft-delete/deactivation), and that a re-loaded page still shows the same data.

**Acceptance Scenarios**:

1. **Given** the data store is configured, **When** a developer seeds initial staff records, **Then** the records are retrievable and include name and active status.
2. **Given** a staff record exists, **When** it is deactivated, **Then** it is excluded from active staff queries but still present in the data store.
3. **Given** a new staff member is added, **When** the attendance page loads, **Then** the new member appears in the staff list.

---

### User Story 2 - Application Can Store and Retrieve Event Data (Priority: P2)

A developer configures the data store so that the application can create booth events, designate one as the active event, and later retrieve attendance records scoped to a specific event.

**Why this priority**: Attendance records must be linked to an event to be meaningful. Event management enables multi-session booth tracking and historical comparisons. It must exist before attendance records can be stored.

**Independent Test**: Can be fully tested by creating multiple events, marking one as active, and verifying that only the active event is returned by the active-event query.

**Acceptance Scenarios**:

1. **Given** the data store is configured, **When** a developer creates an event with a name and date, **Then** the event is stored and retrievable.
2. **Given** multiple events exist, **When** one is marked active, **Then** only that event is returned as the active event.
3. **Given** an event exists, **When** it is queried, **Then** it returns its name, date, and active status.

---

### User Story 3 - Application Can Record and Retrieve Attendance (Priority: P3)

A booth operator checks in a staff member and the system stores the attendance record (including signature) linked to the correct staff member and active event, so that it can later be viewed, filtered, and exported.

**Why this priority**: Attendance recording is the core business function. This data entity depends on both staff and event entities being in place first.

**Independent Test**: Can be fully tested by recording an attendance entry for a given staff member and event, then retrieving it and verifying all fields (staff reference, event reference, check-in time, signature) are intact.

**Acceptance Scenarios**:

1. **Given** a staff member and active event exist, **When** an attendance record is created, **Then** it is stored with a reference to both the staff member and the event, plus a timestamp.
2. **Given** an attendance record includes a signature, **When** the record is retrieved, **Then** the signature data is returned intact.
3. **Given** multiple attendance records exist across different events, **When** queried by event, **Then** only records for that event are returned.
4. **Given** a staff member has already been checked in for an event, **When** a duplicate check-in is attempted, **Then** the system rejects it and returns an appropriate error.

---

### User Story 4 - Application Can Store and Retrieve Settings (Priority: P4)

An admin configures the application by setting a dashboard access PIN, and the system stores that configuration persistently so it survives page refreshes and browser restarts.

**Why this priority**: The settings entity (specifically the hashed PIN) is required by Phase 3 (Dashboard Core) for access control. Establishing it in the data foundation unblocks later phases.

**Independent Test**: Can be fully tested by writing a settings entry (hashed PIN) and verifying it can be retrieved and that the raw PIN is never stored.

**Acceptance Scenarios**:

1. **Given** the data store is configured, **When** a PIN is stored, **Then** only the hashed form of the PIN is persisted — the plain-text PIN is never stored.
2. **Given** a settings entry exists, **When** the application loads, **Then** it can retrieve the current settings (PIN hash, theme preference, language preference).
3. **Given** settings are updated, **When** the application reloads, **Then** the updated settings are returned.

---

### User Story 5 - Data Access Is Controlled (Priority: P1)

The data store enforces access rules so that attendance data, staff data, and settings cannot be read or modified by unauthorized requests beyond what the application explicitly permits.

**Why this priority**: Without access controls, all data is publicly readable and writable. This is a security requirement that must be established from the start, as it is harder to retrofit later and affects all subsequent phases.

**Independent Test**: Can be fully tested by attempting to read or write records without proper authorization and verifying those requests are denied.

**Acceptance Scenarios**:

1. **Given** an unauthenticated request, **When** it attempts to read or modify attendance records, **Then** the request is denied.
2. **Given** the application makes a read request with the correct credentials, **When** querying active staff, **Then** results are returned successfully.
3. **Given** the application makes a write request with the correct credentials, **When** inserting an attendance record, **Then** the record is stored successfully.

---

### Edge Cases

- What happens when the data store is unavailable at app startup? The app must surface a clear error rather than silently showing no staff or a blank screen.
- What happens if no active event exists when the attendance page loads? Attendance recording must be blocked and a meaningful message shown to the operator.
- What happens if the seed script is run more than once? The operation must be idempotent — no duplicate records should be created.
- What happens when signature data is large (up to 500KB per record)? Storage must handle full-resolution canvas signatures without truncation or data loss.
- What happens if the settings table has no row yet? The application must handle a missing settings record gracefully (e.g., use defaults) rather than crashing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST store staff records with at minimum: unique identifier, display name, and active/inactive status.
- **FR-002**: The system MUST support soft-deletion of staff (marking as inactive) without removing the record, preserving historical attendance links.
- **FR-003**: The system MUST store event records with at minimum: unique identifier, name, date, and active/inactive status.
- **FR-004**: The system MUST enforce that only one event is marked active at any given time.
- **FR-005**: The system MUST store attendance records linking a staff member to an event, with a check-in timestamp and optional signature data.
- **FR-006**: The system MUST prevent duplicate attendance records for the same staff member within the same event.
- **FR-007**: The system MUST store application settings including at minimum: hashed dashboard PIN, theme preference, and language preference.
- **FR-008**: The system MUST never store plain-text PIN values — only a one-way hashed representation.
- **FR-009**: The system MUST enforce row-level access controls so that unauthenticated requests cannot read or write any application data.
- **FR-010**: The system MUST be seeded with sample staff members and at least one sample event so the application is demonstrable immediately after setup without manual data entry.
- **FR-011**: The seed operation MUST be idempotent — running it multiple times must not create duplicate records.

### Key Entities

- **Staff**: Represents a person who may attend a booth session. Key attributes: unique ID, full name, active status. Must support soft-deletion to preserve historical attendance links.
- **Event**: Represents a single booth session or occasion. Key attributes: unique ID, name, date, active flag. Only one event may be active at a time.
- **Attendance**: Records a single check-in by a staff member at an event. Key attributes: unique ID, reference to staff, reference to event, check-in timestamp, signature data (optional). Unique per staff-event pair.
- **Settings**: Stores application-wide configuration as a single-row record. Key attributes: hashed PIN, theme preference, language preference.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All four data entities (staff, events, attendance, settings) are fully operable after a fresh setup, with no manual data entry required beyond running the provided setup scripts.
- **SC-002**: A developer can complete the full setup (schema creation, access controls, seed data) in under 15 minutes following the provided instructions.
- **SC-003**: 100% of unauthenticated read or write requests to any data entity are rejected by the access control rules.
- **SC-004**: Seed data provides at least 5 sample staff members and 1 active sample event, making the application immediately demonstrable.
- **SC-005**: Duplicate attendance prevention works in 100% of cases — no two records can exist for the same staff member and event combination.
- **SC-006**: Signature data up to 500KB per record is stored and retrieved without data loss or truncation.

## Assumptions

- A hosted cloud data store (Supabase) will be used; the schema and access control rules target a PostgreSQL-compatible service.
- The application connects using a public anonymous credential for scoped read/write operations; no server-side runtime is required.
- A `config.js` file will hold the connection credentials (project URL and anonymous key); this file must not be committed to source control.
- The initial seed data will use Arabic names consistent with the existing staff list in the current single-file application.
- Signature data is stored as base64-encoded strings derived from an HTML canvas element.
- The settings table is always a single-row store — there will always be exactly one settings record after setup.
- Mobile browser support is in scope for the attendance page but the setup process itself (schema creation, seeding) is a one-time developer task performed on desktop.
