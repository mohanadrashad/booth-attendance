-- =============================================================================
-- Migration 008: Add attendance_date column + update unique constraint
-- =============================================================================
-- Run in the Supabase SQL Editor AFTER migration 007.
-- Enables per-day attendance tracking within a multi-day event.
-- The old (staff_id, event_id) unique constraint is replaced with
-- (staff_id, event_id, attendance_date) so staff can check in once per day.
-- =============================================================================

-- Add the per-day column, backfill existing rows from checked_in_at
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS attendance_date DATE;
UPDATE attendance SET attendance_date = checked_in_at::date WHERE attendance_date IS NULL;
ALTER TABLE attendance ALTER COLUMN attendance_date SET NOT NULL;
ALTER TABLE attendance ALTER COLUMN attendance_date SET DEFAULT CURRENT_DATE;

-- Drop the old event-scoped unique constraint (Postgres auto-names it)
ALTER TABLE attendance DROP CONSTRAINT IF EXISTS attendance_staff_id_event_id_key;

-- Add new day-scoped unique constraint
ALTER TABLE attendance
  ADD CONSTRAINT attendance_staff_event_date_unique
  UNIQUE (staff_id, event_id, attendance_date);
