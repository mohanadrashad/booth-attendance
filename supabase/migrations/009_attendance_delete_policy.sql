-- =============================================================================
-- Migration 009: Add DELETE RLS policy to attendance table
-- =============================================================================
-- Run in the Supabase SQL Editor AFTER migration 008.
-- Allows the dashboard admin to cancel (delete) mistaken attendance records.
-- Security relies on the PIN gate in dashboard.html.
-- =============================================================================

CREATE POLICY "anon can delete attendance"
  ON attendance FOR DELETE
  TO anon
  USING (true);
