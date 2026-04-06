-- =============================================================================
-- Migration 002: Add start_time column to events table
-- =============================================================================
-- Run in the Supabase SQL Editor before using the Events section of dashboard.html.
-- start_time is nullable — NULL means no late-arrival flagging for that event.
-- =============================================================================

ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT NULL;
