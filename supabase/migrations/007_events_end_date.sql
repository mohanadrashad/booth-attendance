-- =============================================================================
-- Migration 007: Add end_date to events table
-- =============================================================================
-- Run in the Supabase SQL Editor AFTER migration 006.
-- Allows events to span multiple days (start_date = event_date, end_date = new).
-- Existing single-day events are backfilled: end_date = event_date.
-- =============================================================================

ALTER TABLE events ADD COLUMN IF NOT EXISTS end_date DATE;

-- Backfill: existing single-day events get end_date = event_date
UPDATE events SET end_date = event_date WHERE end_date IS NULL;
