-- =============================================================================
-- Migration 004: Settings table RLS — Dashboard write access
-- =============================================================================
-- Run in the Supabase SQL Editor before using the Settings section of dashboard.html.
-- Required for the PIN change feature.
-- Security relies on the PIN gate in dashboard.html.
-- =============================================================================

CREATE POLICY "anon can update settings"
  ON settings FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
