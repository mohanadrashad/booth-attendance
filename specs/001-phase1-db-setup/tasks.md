# Tasks: Phase 1 — Data Foundation

**Input**: Design documents from `/specs/001-phase1-db-setup/`  
**Branch**: `001-phase1-db-setup`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: No test tasks generated — no automated test framework is in scope for this project (manual browser verification via Supabase SQL Editor per quickstart.md).

**Organization**: Tasks are grouped by user story. Each story adds one table + its RLS policy + seed data to `supabase/schema.sql` and `supabase/seed.sql`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the file structure and credentials template before writing any SQL.

- [x] T001 Create `supabase/` directory at repository root
- [x] T002 [P] Create `config.example.js` at repository root with placeholder `SUPABASE_URL` and `SUPABASE_ANON_KEY` constants
- [x] T003 [P] Create or update `.gitignore` at repository root to exclude `config.js`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Initialise `supabase/schema.sql` and `supabase/seed.sql` with the shared header and UUID extension. Both user story phases write into these files sequentially.

**⚠️ CRITICAL**: No user story SQL can be added until this phase is complete.

- [x] T004 Create `supabase/schema.sql` with file header comment, `CREATE EXTENSION IF NOT EXISTS "pgcrypto";` for UUID generation, and section dividers for each table
- [x] T005 Create `supabase/seed.sql` with file header comment and idempotency note explaining the `ON CONFLICT DO NOTHING` pattern used throughout

**Checkpoint**: Both SQL files exist with their headers. User story phases can now add their table DDL and seed rows.

---

## Phase 3: User Story 1 — Staff Data (Priority: P1) 🎯 MVP

**Goal**: The application can persistently store and retrieve staff members, including soft-deletion to preserve attendance history.

**Independent Test**: Run `supabase/schema.sql` + `supabase/seed.sql` in the Supabase SQL Editor, then execute `SELECT id, name, is_active FROM staff ORDER BY name;` — should return 5 rows all with `is_active = true`.

- [x] T006 [US1] Add `staff` table DDL to `supabase/schema.sql`: columns `id` (UUID PK default gen_random_uuid()), `name` (TEXT NOT NULL), `is_active` (BOOLEAN NOT NULL DEFAULT true), `created_at` (TIMESTAMPTZ NOT NULL DEFAULT now())
- [x] T007 [US1] Add RLS rules for `staff` to `supabase/schema.sql`: `ALTER TABLE staff ENABLE ROW LEVEL SECURITY;` + policy granting `anon` role SELECT only (no INSERT/UPDATE/DELETE)
- [x] T008 [US1] Add 5 sample Arabic staff rows to `supabase/seed.sql` using hardcoded stable UUIDs (`00000000-0000-0000-0000-00000000000N` pattern) with `INSERT ... ON CONFLICT (id) DO NOTHING`

**Checkpoint**: Staff table is live, seeded, and readable by the anon key. Anon write attempts are rejected.

---

## Phase 4: User Story 2 — Event Data (Priority: P2)

**Goal**: The application can store booth events, designate one as active, and retrieve it to scope attendance check-ins.

**Independent Test**: After running both SQL files, execute `SELECT id, name, event_date FROM events WHERE is_active = true;` — should return exactly 1 row.

- [x] T009 [US2] Add `events` table DDL to `supabase/schema.sql`: columns `id` (UUID PK), `name` (TEXT NOT NULL), `event_date` (DATE NOT NULL), `is_active` (BOOLEAN NOT NULL DEFAULT false), `created_at` (TIMESTAMPTZ NOT NULL DEFAULT now())
- [x] T010 [US2] Add RLS rules for `events` to `supabase/schema.sql`: enable RLS + anon SELECT only policy
- [x] T011 [US2] Add 1 active sample event row to `supabase/seed.sql` with a hardcoded stable UUID, `is_active = true`, and today's date using `ON CONFLICT (id) DO NOTHING`

**Checkpoint**: Events table is live. Active event query returns exactly one row. Anon cannot insert/update events.

---

## Phase 5: User Story 3 — Attendance Records (Priority: P3)

**Goal**: The application can insert and retrieve attendance records linking a staff member to an event, including optional signature data, with duplicate check-ins blocked by a database constraint.

**Independent Test**: Insert one attendance row referencing a seeded staff ID and event ID; verify it is stored with a timestamp. Attempt a duplicate insert for the same pair; verify it is rejected with a unique constraint error.

- [x] T012 [US3] Add `attendance` table DDL to `supabase/schema.sql`: columns `id` (UUID PK), `staff_id` (UUID NOT NULL FK → staff(id) ON DELETE RESTRICT), `event_id` (UUID NOT NULL FK → events(id) ON DELETE RESTRICT), `checked_in_at` (TIMESTAMPTZ NOT NULL DEFAULT now()), `signature_data` (TEXT NULLABLE), `created_at` (TIMESTAMPTZ NOT NULL DEFAULT now()); add `UNIQUE (staff_id, event_id)` constraint
- [x] T013 [US3] Add RLS rules for `attendance` to `supabase/schema.sql`: enable RLS + anon SELECT policy + anon INSERT policy (no UPDATE/DELETE)

**Checkpoint**: Attendance table is live. Anon can insert check-in records. Duplicate staff+event pair is blocked. Anon cannot update or delete records.

---

## Phase 6: User Story 4 — Settings (Priority: P4)

**Goal**: The application can persistently store and retrieve app configuration (hashed PIN, theme, language) as a single-row record that survives page reloads.

**Independent Test**: After running both SQL files, execute `SELECT theme, language, length(pin_hash) AS hash_len FROM settings;` — should return 1 row with `hash_len = 64` (SHA-256 hex length).

- [x] T014 [US4] Add `settings` table DDL to `supabase/schema.sql`: columns `id` (INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1)), `pin_hash` (TEXT NOT NULL), `theme` (TEXT NOT NULL DEFAULT 'dark'), `language` (TEXT NOT NULL DEFAULT 'ar'), `updated_at` (TIMESTAMPTZ NOT NULL DEFAULT now())
- [x] T015 [US4] Add RLS rules for `settings` to `supabase/schema.sql`: enable RLS + anon SELECT only policy
- [x] T016 [US4] Add default settings row to `supabase/seed.sql`: `id = 1`, `pin_hash` = SHA-256 hex of `'1234'` (hardcoded: `03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4`), `theme = 'dark'`, `language = 'ar'`, using `INSERT ... ON CONFLICT (id) DO NOTHING`

**Checkpoint**: Settings table is live with one row. PIN hash is 64 characters. Anon cannot write to settings.

---

## Phase 7: User Story 5 — Access Control Verification (Priority: P1)

**Goal**: Confirm that the RLS policies across all four tables actually enforce their intended permissions — no unauthenticated writes to protected tables, no reads denied where reads are needed.

**Independent Test**: Using the Supabase SQL Editor running as the `anon` role, verify each policy in the matrix from `specs/001-phase1-db-setup/contracts/supabase-queries.md`.

- [ ] T017 [US5] Verify anon SELECT works on all four tables: run `SELECT count(*) FROM staff; SELECT count(*) FROM events; SELECT count(*) FROM settings; SELECT count(*) FROM attendance;` in Supabase SQL Editor as anon role — all must return without error
- [ ] T018 [US5] Verify anon INSERT is blocked on protected tables: attempt `INSERT INTO staff (name) VALUES ('test');`, `INSERT INTO events (name, event_date) VALUES ('test', now());`, `INSERT INTO settings (id, pin_hash) VALUES (1, 'x');` as anon — all must return RLS policy violation errors
- [ ] T019 [US5] Verify anon INSERT succeeds on `attendance`: insert a test record using a seeded `staff_id` and `event_id` as anon — must succeed; then verify the duplicate insert is rejected with a unique constraint error

**Checkpoint**: All RLS policies confirmed. Access control matrix from data-model.md is validated.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end validation and documentation completeness.

- [ ] T020 [P] Follow `specs/001-phase1-db-setup/quickstart.md` Steps 1–5 from scratch on a fresh Supabase project to verify the setup guide is accurate and complete
- [ ] T021 [P] Verify `supabase/seed.sql` is idempotent: run it a second time and confirm `SELECT count(*) FROM staff;` still returns 5 (not 10)
- [x] T022 Add a comment block to the top of `supabase/schema.sql` listing the four tables, their purpose, and a note that all admin write operations require service-role access (Phase 3)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — creates the SQL files before any table DDL is added
- **US1 Staff (Phase 3)**: Depends on Phase 2 — **blocks all other user stories** (attendance FKs to staff)
- **US2 Events (Phase 4)**: Depends on Phase 2; can run in parallel with US1 (different table, no FK dependency until Phase 5)
- **US3 Attendance (Phase 5)**: Depends on US1 and US2 both complete (FK references both)
- **US4 Settings (Phase 6)**: Depends on Phase 2 only; independent of US1/US2/US3
- **US5 Verification (Phase 7)**: Depends on all four tables existing (Phases 3–6 complete)
- **Polish (Phase 8)**: Depends on Phase 7 complete

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundation)
                        ├──► US1 Staff ──────┐
                        ├──► US2 Events ─────┤──► US3 Attendance ──► US5 Verify ──► Polish
                        └──► US4 Settings ───┘
```

### Parallel Opportunities

- T002 and T003 (Phase 1) can run in parallel
- T004 and T005 (Phase 2) can run in parallel
- US1 (Phase 3) and US2 (Phase 4) can run in parallel — they write to the same `schema.sql` and `seed.sql` files, but different sections; coordinate to avoid merge conflicts if working as a team
- US4 (Phase 6) can run in parallel with US1, US2, and US3
- T017, T018, T019 (Phase 7) can run in parallel
- T020 and T021 (Phase 8) can run in parallel

---

## Parallel Example: Phases 3 and 4

```
# If working solo, do sequentially: Phase 3 → Phase 4
# If working as a team, both can add to schema.sql simultaneously in separate sections:

Developer A (Phase 3 - Staff):
  Task T006: Add staff table DDL to supabase/schema.sql
  Task T007: Add staff RLS to supabase/schema.sql
  Task T008: Add staff seed rows to supabase/seed.sql

Developer B (Phase 4 - Events, in parallel):
  Task T009: Add events table DDL to supabase/schema.sql
  Task T010: Add events RLS to supabase/schema.sql
  Task T011: Add event seed row to supabase/seed.sql
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T005)
3. Complete Phase 3: US1 — Staff (T006–T008)
4. **STOP and VALIDATE**: Run schema + seed in Supabase, confirm staff SELECT works and write is blocked
5. This alone is enough to unblock Phase 2 of the broader project (attendance page can now load real staff)

### Incremental Delivery

1. Setup + Foundation → SQL files exist
2. Add Staff (US1) → Staff reads work ✓
3. Add Events (US2) → Active event loads ✓
4. Add Attendance (US3) → Check-in writes work ✓
5. Add Settings (US4) → PIN gate reads work ✓
6. Verify Access Controls (US5) → Security confirmed ✓
7. Polish → Setup guide validated ✓

---

## Notes

- All SQL tasks write to either `supabase/schema.sql` or `supabase/seed.sql` — there are no `src/` files in this phase
- [P] marks tasks that touch separate files or separate sections with no shared dependencies
- Each user story phase is independently executable in the Supabase SQL Editor
- The seed PIN hash for `1234` is: `03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4`
- Change the default PIN immediately after first login in Phase 3 (dashboard)
- Commit after each phase checkpoint, not after every individual task
