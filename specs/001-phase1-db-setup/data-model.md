# Data Model: Phase 1 — Data Foundation

**Date**: 2026-04-03  
**Branch**: `001-phase1-db-setup`

---

## Entities

### 1. `staff`

Represents a person who may attend a booth session. Supports soft-deletion to preserve attendance history.

| Column      | Type        | Constraints                        | Description                              |
|-------------|-------------|-------------------------------------|------------------------------------------|
| `id`        | UUID        | PRIMARY KEY, DEFAULT gen_random_uuid() | Stable identifier                     |
| `name`      | TEXT        | NOT NULL                            | Full display name (Arabic)               |
| `is_active` | BOOLEAN     | NOT NULL, DEFAULT true              | false = soft-deleted; excluded from active queries |
| `created_at`| TIMESTAMPTZ | NOT NULL, DEFAULT now()             | Record creation time                     |

**Indexes**: Primary key on `id`. Implicit index on `is_active` via query patterns.  
**Validation rules**: `name` must be non-empty. `is_active` defaults to `true` on insert.  
**Notes**: No hard-delete. Deactivating a staff member preserves all linked attendance records.

---

### 2. `events`

Represents a single booth session or occasion. Only one event may be active at a time (enforced at application layer).

| Column      | Type        | Constraints                        | Description                              |
|-------------|-------------|-------------------------------------|------------------------------------------|
| `id`        | UUID        | PRIMARY KEY, DEFAULT gen_random_uuid() | Stable identifier                     |
| `name`      | TEXT        | NOT NULL                            | Human-readable event name               |
| `event_date`| DATE        | NOT NULL                            | Date the event takes place               |
| `is_active` | BOOLEAN     | NOT NULL, DEFAULT false             | Only one row should be true at a time    |
| `created_at`| TIMESTAMPTZ | NOT NULL, DEFAULT now()             | Record creation time                     |

**Indexes**: Primary key on `id`.  
**Validation rules**: `name` must be non-empty. `event_date` must be a valid date.  
**Active event query**: `SELECT * FROM events WHERE is_active = true LIMIT 1`  
**Notes**: Switching active event = set old row `is_active = false`, new row `is_active = true` (Phase 4 will add a DB-level constraint or trigger if concurrency becomes a concern).

---

### 3. `attendance`

Records a single check-in by a staff member at an event. Each staff-event pair is unique.

| Column           | Type        | Constraints                                      | Description                          |
|------------------|-------------|--------------------------------------------------|--------------------------------------|
| `id`             | UUID        | PRIMARY KEY, DEFAULT gen_random_uuid()           | Stable identifier                    |
| `staff_id`       | UUID        | NOT NULL, FK → staff(id) ON DELETE RESTRICT      | Who checked in                       |
| `event_id`       | UUID        | NOT NULL, FK → events(id) ON DELETE RESTRICT     | Which event                          |
| `checked_in_at`  | TIMESTAMPTZ | NOT NULL, DEFAULT now()                          | Exact check-in timestamp             |
| `signature_data` | TEXT        | NULLABLE                                         | Base64-encoded PNG data URL from canvas |
| `created_at`     | TIMESTAMPTZ | NOT NULL, DEFAULT now()                          | Record creation time                 |

**Unique constraint**: `UNIQUE (staff_id, event_id)` — prevents duplicate check-ins for the same person at the same event.  
**Indexes**: Primary key on `id`. Unique index on `(staff_id, event_id)`. FK indexes on `staff_id` and `event_id`.  
**Validation rules**: Both `staff_id` and `event_id` must reference existing rows. `signature_data` is optional but when present must be a valid base64 data URL string.  
**Notes**: `ON DELETE RESTRICT` on both FKs means staff and events cannot be hard-deleted while attendance records exist. Use soft-delete (is_active = false) for staff and events instead.

---

### 4. `settings`

Stores application-wide configuration as a single-row record. Always exactly one row after setup.

| Column              | Type        | Constraints                        | Description                              |
|---------------------|-------------|-------------------------------------|------------------------------------------|
| `id`                | INTEGER     | PRIMARY KEY, DEFAULT 1, CHECK (id = 1) | Enforces single-row pattern           |
| `pin_hash`          | TEXT        | NOT NULL                            | SHA-256 hex digest of the 4-digit PIN   |
| `theme`             | TEXT        | NOT NULL, DEFAULT 'dark'            | 'dark' or 'light'                        |
| `language`          | TEXT        | NOT NULL, DEFAULT 'ar'              | 'ar' (Arabic) or future locale codes     |
| `updated_at`        | TIMESTAMPTZ | NOT NULL, DEFAULT now()             | Last settings update time                |

**Unique constraint**: `CHECK (id = 1)` combined with INTEGER PRIMARY KEY enforces exactly one row.  
**Validation rules**: `pin_hash` must be a 64-character hex string (SHA-256 output). `theme` must be 'dark' or 'light'. `language` must be 'ar' (Phase 5 adds more locales).  
**Notes**: The single-row pattern using `id = 1` is idiomatic for configuration tables. Insert uses `ON CONFLICT (id) DO UPDATE` for upsert semantics.

---

## Entity Relationships

```
staff ──────────────┐
  id (PK)           │ staff_id (FK, RESTRICT)
  name              │
  is_active         ├──► attendance
  created_at        │      id (PK)
                    │      staff_id (FK)
events ─────────────┤      event_id (FK)
  id (PK)           │      checked_in_at
  name              │      signature_data
  event_date        │      created_at
  is_active         │
  created_at        │ event_id (FK, RESTRICT)
                    └──────────────────────

settings (singleton)
  id = 1 (always)
  pin_hash
  theme
  language
  updated_at
```

---

## RLS Policy Summary

All tables have RLS enabled. Policies grant the `anon` role the minimum permissions needed for the attendance page.

| Table        | anon SELECT | anon INSERT | anon UPDATE | anon DELETE | Notes                              |
|--------------|:-----------:|:-----------:|:-----------:|:-----------:|------------------------------------|
| `staff`      | ✓           | ✗           | ✗           | ✗           | Read-only; writes via admin (Phase 3) |
| `events`     | ✓           | ✗           | ✗           | ✗           | Read-only; writes via admin (Phase 3) |
| `attendance` | ✓           | ✓           | ✗           | ✗           | Check-in inserts from attendance page |
| `settings`   | ✓           | ✗           | ✗           | ✗           | Read for PIN hash; update via admin (Phase 3) |

---

## State Transitions

### Staff lifecycle
```
Active (is_active = true) ──[admin deactivates]──► Inactive (is_active = false)
```
No re-activation needed in Phase 1–2 scope (Phase 3 dashboard adds edit capability).

### Event lifecycle
```
Inactive (is_active = false) ──[admin activates]──► Active (is_active = true)
Active ──[admin switches event]──► Inactive
```
Only one event is active at a time. Switching is a two-step update (Phase 4).

### Attendance lifecycle
```
[staff card clicked] ──[signature captured]──► Record inserted (no further transitions)
```
Attendance records are immutable once written. No edit or delete in Phase 1–2 scope.
