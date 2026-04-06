-- =============================================================================
-- Migration 006: Add sign-out columns and UPDATE policy to attendance table
-- =============================================================================
-- Run in the Supabase SQL Editor AFTER migration 005.
-- Required for the check-out signature flow in booth-attendance.html.
-- =============================================================================

ALTER TABLE attendance
  ADD COLUMN IF NOT EXISTS checked_out_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS exit_signature_data TEXT;

-- Allow anon to UPDATE attendance records (for check-out flow).
-- Security relies on the PIN gate in dashboard.html and the event-scoped
-- check-in flow in booth-attendance.html.
CREATE POLICY "anon can update attendance"
  ON attendance FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
