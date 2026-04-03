# Research: Phase 1 — Data Foundation

**Date**: 2026-04-03  
**Branch**: `001-phase1-db-setup`

---

## 1. Supabase Schema Design for Attendance Tracking

**Decision**: Use four tables (`staff`, `events`, `attendance`, `settings`) with UUID primary keys, `created_at` timestamps, and explicit foreign key constraints with `ON DELETE RESTRICT` to preserve attendance history.

**Rationale**: UUIDs avoid sequential ID enumeration (security). `ON DELETE RESTRICT` ensures attendance records are never silently orphaned if a staff member or event is accidentally deleted — the operation is blocked, forcing a deliberate soft-delete workflow. This is safer than `ON DELETE CASCADE` for audit data.

**Alternatives considered**:
- Integer auto-increment PKs: Simpler but enumerable; rejected in favour of UUIDs for the settings and attendance tables.
- `ON DELETE CASCADE`: Would silently remove attendance history if staff/events are deleted; rejected.
- Storing signatures in a separate `signatures` table: Adds a join for every attendance read; rejected in favour of a `signature_data` text column directly on `attendance` (simpler, no join needed at this scale).

---

## 2. Row-Level Security (RLS) Strategy

**Decision**: Enable RLS on all four tables. Use a single **anon key policy** pattern: the Supabase `anon` role can `SELECT` and `INSERT` on `staff`, `events`, and `attendance`. The `settings` table allows `SELECT` only for anon (the dashboard PIN hash must be readable to verify it); PIN updates go through a dedicated Supabase function or service-role call (Phase 3).

**Rationale**: The attendance page (public-facing) needs to read staff and events, and write attendance records. It must never be able to modify staff or events. The dashboard (Phase 3) will use a PIN-verified session; at this phase, settings reads are sufficient for anon.

**Policies defined**:

| Table      | anon SELECT | anon INSERT | anon UPDATE | anon DELETE |
|------------|:-----------:|:-----------:|:-----------:|:-----------:|
| staff      | ✓           | ✗           | ✗           | ✗           |
| events     | ✓           | ✗           | ✗           | ✗           |
| attendance | ✓           | ✓           | ✗           | ✗           |
| settings   | ✓           | ✗           | ✗           | ✗           |

Admin write operations (staff CRUD, event management, settings updates) will be handled in Phase 3 using service-role or a Supabase Edge Function after PIN verification.

**Alternatives considered**:
- No RLS (public schema): Rejected — leaves all data readable/writable without credentials.
- JWT-based user auth per staff member: Over-engineered for a booth kiosk; rejected.
- Service-role key in browser: Never acceptable — exposes admin access; rejected.

---

## 3. PIN Hashing in Browser (No Server Runtime)

**Decision**: Use the **Web Crypto API** (`crypto.subtle.digest('SHA-256', ...)`) built into all modern browsers. Hash the 4-digit PIN before storing or comparing. Store only the hex-encoded SHA-256 hash in the `settings` table.

**Rationale**: Web Crypto API is available in all modern browsers (Chrome 37+, Firefox 34+, Safari 11+) without any library. No Node.js or server required. SHA-256 is sufficient for a 4-digit PIN used as a low-stakes access gate (not a password vault).

**Implementation note**: A 4-digit PIN has only 10,000 possible values, making SHA-256 alone trivially brutable offline. This is acceptable for a booth admin gate — it is not protecting financial data. If stronger protection is needed in future, add a salt stored server-side.

**Alternatives considered**:
- bcrypt/argon2 in browser: Requires a library (~50KB+), adds complexity; rejected.
- Plain-text PIN in DB: Never acceptable; rejected.
- Server-side hashing via Supabase Edge Function: Adds latency and complexity for Phase 1; deferred to Phase 3 if needed.

---

## 4. Signature Storage

**Decision**: Store signatures as `TEXT` (base64-encoded PNG data URLs) directly in the `attendance` table as a nullable column (`signature_data TEXT`).

**Rationale**: Canvas `toDataURL('image/png')` produces a base64 string. At typical canvas sizes (400×200px), compressed PNG signatures are 10–80KB, well within PostgreSQL's TEXT column limits (up to 1GB). Storing inline avoids a separate storage bucket, join queries, and the complexity of Supabase Storage bucket policies.

**Size estimate**: 50 staff × 500 events/year × ~50KB avg = ~1.2GB/year at maximum. For a booth app this is acceptable; Supabase free tier supports 500MB DB, so monitoring will be needed at scale.

**Alternatives considered**:
- Supabase Storage bucket: Better for large files but adds bucket policy complexity and a two-step write; overkill at this scale.
- Store as BYTEA (binary): No advantage over TEXT for base64; TEXT is simpler.
- Thumbnail compression on write: Premature optimisation; deferred.

---

## 5. Idempotent Seed Data Pattern

**Decision**: Use `INSERT ... ON CONFLICT DO NOTHING` with explicit, stable UUIDs for seed records. This makes the seed script safely re-runnable.

**Rationale**: If UUIDs are generated dynamically (e.g., `gen_random_uuid()`), each run creates new rows. Using hardcoded UUIDs in the seed script means re-running it hits the unique constraint and skips gracefully.

**Pattern**:
```sql
INSERT INTO staff (id, name, is_active)
VALUES ('00000000-0000-0000-0000-000000000001', 'أحمد العتيبي', true)
ON CONFLICT (id) DO NOTHING;
```

**Alternatives considered**:
- `INSERT ... ON CONFLICT DO UPDATE`: Would overwrite manual changes on re-seed; rejected.
- Checking existence before insert: Verbose; `ON CONFLICT DO NOTHING` is idiomatic SQL.

---

## 6. Single Active Event Constraint

**Decision**: Enforce "only one active event" at the **application layer** (Phase 2+) rather than a database-level partial unique index, for simplicity.

**Rationale**: A `UNIQUE` partial index on `(is_active) WHERE is_active = true` would enforce this at DB level but requires PostgreSQL-specific syntax and can complicate event switching (must update two rows atomically). Given the app has no concurrent admin sessions in Phase 1, application-layer enforcement is sufficient and simpler.

**Deferred**: If Phase 4 introduces concurrent admin access, a DB-level constraint or trigger should be added.

**Alternatives considered**:
- `UNIQUE` partial index: Correct but complex to switch; deferred.
- Trigger to auto-deactivate others: Good but adds schema complexity; deferred to Phase 4.

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| Primary keys | UUID v4 |
| Foreign key delete behaviour | RESTRICT (no cascades) |
| RLS pattern | Anon read-only for staff/events/settings; anon insert for attendance |
| PIN hashing | Web Crypto API SHA-256, hex-encoded |
| Signature storage | TEXT (base64 PNG data URL) inline in attendance table |
| Idempotent seed | Stable hardcoded UUIDs + `ON CONFLICT DO NOTHING` |
| Active event enforcement | Application layer (Phase 1); DB constraint deferred to Phase 4 |
