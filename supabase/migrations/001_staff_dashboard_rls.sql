-- =============================================================================
-- Migration 001: Staff table RLS — Dashboard write access
-- =============================================================================
-- Run this in the Supabase SQL Editor before using dashboard.html.
-- Adds anon INSERT and UPDATE to the staff table.
-- Security relies on the PIN gate in dashboard.html — the anon key is already
-- public in the browser, so RLS here provides defense-in-depth, not primary auth.
-- =============================================================================

CREATE POLICY "anon can insert staff"
  ON staff FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "anon can update staff"
  ON staff FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
