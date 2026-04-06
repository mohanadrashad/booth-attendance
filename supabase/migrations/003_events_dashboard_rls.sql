-- =============================================================================
-- Migration 003: Events table RLS — Dashboard write access
-- =============================================================================
-- Run in the Supabase SQL Editor before using the Events section of dashboard.html.
-- Security relies on the PIN gate in dashboard.html.
-- =============================================================================

CREATE POLICY "anon can insert events"
  ON events FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "anon can update events"
  ON events FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "anon can delete events"
  ON events FOR DELETE
  TO anon
  USING (true);
