# Quickstart: Phase 1 — Data Foundation Setup

**Date**: 2026-04-03  
**Branch**: `001-phase1-db-setup`

This guide walks a developer through setting up the Supabase data store from scratch. Estimated time: under 15 minutes.

---

## Prerequisites

- A [Supabase](https://supabase.com) account (free tier is sufficient)
- Access to the project repository
- A modern web browser

---

## Step 1: Create a Supabase Project

1. Log in to [supabase.com](https://supabase.com) and click **New Project**.
2. Choose your organisation, give the project a name (e.g., `booth-attendance`), set a database password, and select a region close to your users.
3. Wait ~2 minutes for the project to provision.

---

## Step 2: Configure `config.js`

1. In the Supabase dashboard, go to **Project Settings → API**.
2. Copy the **Project URL** and the **`anon` public key**.
3. In the repository root, copy `config.example.js` to `config.js`:
   ```
   cp config.example.js config.js
   ```
4. Open `config.js` and fill in your values:
   ```js
   const SUPABASE_URL = 'https://your-project-id.supabase.co';
   const SUPABASE_ANON_KEY = 'your-anon-key-here';
   ```
5. **Do not commit `config.js`** — it is listed in `.gitignore`.

---

## Step 3: Run the Schema

1. In the Supabase dashboard, go to **SQL Editor → New query**.
2. Open `supabase/schema.sql` from the repository and paste the entire contents.
3. Click **Run**. You should see no errors.

This creates the `staff`, `events`, `attendance`, and `settings` tables with all constraints and RLS policies.

---

## Step 4: Run the Seed Data

1. In the SQL Editor, open a new query.
2. Open `supabase/seed.sql` from the repository and paste the entire contents.
3. Click **Run**. You should see no errors.

This inserts 5 sample Arabic staff members, 1 active sample event, and the default settings row (PIN: `1234`, theme: `dark`, language: `ar`).

The seed is idempotent — you can run it again without creating duplicates.

---

## Step 5: Verify the Setup

Run these queries in the SQL Editor to confirm everything is in place:

```sql
-- Check staff
SELECT id, name, is_active FROM staff ORDER BY name;

-- Check active event
SELECT id, name, event_date FROM events WHERE is_active = true;

-- Check settings
SELECT theme, language, length(pin_hash) AS pin_hash_length FROM settings;
-- pin_hash_length should be 64 (SHA-256 hex)
```

Expected results:
- 5 staff rows, all `is_active = true`
- 1 event row returned
- 1 settings row with `pin_hash_length = 64`

---

## Step 6: Test RLS Policies

Open the project in a browser (open `booth-attendance.html` locally with `config.js` in place).

- The staff grid should load from Supabase (replace the hardcoded list — this is Phase 2 work, but you can test the connection independently by opening the browser console and running):

```js
const { data } = await supabase.from('staff').select('*').eq('is_active', true);
console.log(data);
```

You should see the 5 seed staff members.

---

## Default Credentials

| Setting  | Value  |
|----------|--------|
| Dashboard PIN | `1234` (change this after setup) |
| Theme    | `dark` |
| Language | `ar`   |

**Important**: Change the default PIN before using the dashboard in production (Phase 3).

---

## File Reference

| File                  | Purpose                                       |
|-----------------------|-----------------------------------------------|
| `config.example.js`   | Template — commit this, not `config.js`        |
| `config.js`           | Your actual credentials — never commit this    |
| `supabase/schema.sql` | Full table definitions, constraints, RLS rules |
| `supabase/seed.sql`   | Sample data — idempotent, safe to re-run      |
