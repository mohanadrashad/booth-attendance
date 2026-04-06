-- =============================================================================
-- Booth Attendance — Database Schema
-- =============================================================================
-- Tables: staff, events, attendance, settings
-- All tables have RLS enabled. The anon key may only:
--   • SELECT from: staff, events, attendance, settings
--   • INSERT into: attendance only
-- All admin write operations (staff CRUD, event management, settings updates)
-- require service-role access and are implemented in Phase 3 (dashboard).
-- =============================================================================

-- Enable the pgcrypto extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TABLE: staff
-- Represents a person who may attend a booth session.
-- Soft-delete via is_active = false preserves attendance history.
-- =============================================================================

CREATE TABLE IF NOT EXISTS staff (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT         NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- RLS: staff
-- anon role may only SELECT active/inactive staff (needed by attendance page).
-- No inserts, updates, or deletes via anon key.
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon can select staff"
  ON staff FOR SELECT
  TO anon
  USING (true);

-- =============================================================================
-- TABLE: events
-- Represents a single booth session or occasion.
-- Only one event should have is_active = true at a time (enforced at app layer).
-- =============================================================================

CREATE TABLE IF NOT EXISTS events (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT         NOT NULL,
  event_date  DATE         NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- RLS: events
-- anon role may only SELECT events (needed to load active event on attendance page).
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon can select events"
  ON events FOR SELECT
  TO anon
  USING (true);

-- =============================================================================
-- TABLE: attendance
-- Records a single check-in by a staff member at an event.
-- UNIQUE(staff_id, event_id) prevents duplicate check-ins.
-- FKs use ON DELETE RESTRICT to block hard-deleting staff/events that have
-- attendance records — use soft-delete (is_active = false) instead.
-- =============================================================================

CREATE TABLE IF NOT EXISTS attendance (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id        UUID         NOT NULL REFERENCES staff(id)  ON DELETE RESTRICT,
  event_id        UUID         NOT NULL REFERENCES events(id) ON DELETE RESTRICT,
  checked_in_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  signature_data  TEXT,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (staff_id, event_id)
);

-- RLS: attendance
-- anon role may SELECT (to show who has checked in) and INSERT (check-in action).
-- No updates or deletes — attendance records are immutable once written.
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon can select attendance"
  ON attendance FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "anon can insert attendance"
  ON attendance FOR INSERT
  TO anon
  WITH CHECK (true);

-- =============================================================================
-- TABLE: settings
-- Stores application-wide configuration as a single-row record.
-- CHECK (id = 1) enforces the single-row constraint.
-- pin_hash stores the SHA-256 hex digest of the 4-digit dashboard PIN.
-- The plain-text PIN is never stored.
-- =============================================================================

CREATE TABLE IF NOT EXISTS settings (
  id          INTEGER      PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  pin_hash    TEXT         NOT NULL,
  theme       TEXT         NOT NULL DEFAULT 'dark',
  language    TEXT         NOT NULL DEFAULT 'ar',
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- RLS: settings
-- anon role may SELECT (needed to read pin_hash for dashboard PIN verification).
-- Updates go through service-role after PIN verification (Phase 3).
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon can select settings"
  ON settings FOR SELECT
  TO anon
  USING (true);
