-- =============================================================================
-- Migration 005: Add department column to staff table
-- =============================================================================
-- Run in the Supabase SQL Editor before using department features.
-- The column is nullable so existing rows are unaffected.
-- =============================================================================

ALTER TABLE staff ADD COLUMN IF NOT EXISTS department TEXT;
