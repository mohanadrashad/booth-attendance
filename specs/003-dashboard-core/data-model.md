# Data Model: Phase 3 — Dashboard Core

**Date**: 2026-04-05  
**Branch**: `003-dashboard-core`

> **DB schema**: Already defined in Phase 1. This document describes the JavaScript in-memory state and the new SQL migration needed for dashboard write access.

---

## New SQL Migration Required

`supabase/migrations/001_staff_dashboard_rls.sql` — must be run in the Supabase SQL Editor before the dashboard can write to the `staff` table.

```sql
CREATE POLICY "anon can insert staff"
  ON staff FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update staff"
  ON staff FOR UPDATE TO anon USING (true) WITH CHECK (true);
```

---

## Module-Level State Variables (`dashboard.html`)

```js
let _supabase = null;       // Initialized after config guard (same pattern as Phase 2)
let STAFF = [];             // [{ id: UUID, name: string, is_active: boolean, created_at: string }]
let searchQuery = '';       // Current search filter string
let modalMode = null;       // 'add' | 'edit' | null
let editStaffId = null;     // UUID of staff being edited | null
let deleteConfirmId = null; // UUID of staff pending delete confirmation | null
```

---

## Entities Used

### `settings` (read-only in this phase)

| Field      | Type    | Used For                          |
|------------|---------|-----------------------------------|
| `pin_hash` | TEXT    | Compare against hashed PIN entry  |

Query: `SELECT pin_hash FROM settings WHERE id = 1` — called once on PIN submit.

---

### `staff` (full CRUD)

| Field        | Type        | Read | Write | Notes                                      |
|--------------|-------------|------|-------|--------------------------------------------|
| `id`         | UUID        | ✓    | —     | Auto-generated on INSERT                   |
| `name`       | TEXT        | ✓    | ✓     | Add + Edit target                          |
| `is_active`  | BOOLEAN     | ✓    | ✓     | Soft-delete sets to `false`                |
| `created_at` | TIMESTAMPTZ | ✓    | —     | Auto-generated, shown in card detail       |

**Read query** (on dashboard unlock):
```sql
SELECT id, name, is_active, created_at FROM staff ORDER BY name
```
Returns all staff (active + inactive) for the dashboard list.

**INSERT** (add staff):
```sql
INSERT INTO staff (name) VALUES ($name) RETURNING id, name, is_active, created_at
```

**UPDATE name** (edit staff):
```sql
UPDATE staff SET name = $name WHERE id = $id RETURNING id, name, is_active, created_at
```

**UPDATE is_active** (soft-delete):
```sql
UPDATE staff SET is_active = false WHERE id = $id
```

---

## State Transitions

### Authentication Flow

```
Page load
  ↓
sessionStorage.getItem('dashboard_auth') === '1'?
  YES → showDashboard() → loadStaff()
  NO  → showPinScreen()

PIN submit
  ↓
hashPin(input) → compare with settings.pin_hash
  MATCH   → sessionStorage.setItem('dashboard_auth','1') → showDashboard() → loadStaff()
  MISMATCH → showPinError() → clear input

Logout
  ↓
sessionStorage.removeItem('dashboard_auth') → showPinScreen()
```

### Staff List State

```
loadStaff() → STAFF[] populated from DB → renderStaffList()

Search input event → searchQuery updated → renderStaffList() (client-side filter)

Add staff
  openStaffModal('add') → user enters name → submitStaffModal()
  ↓ INSERT to DB → push to STAFF[] → renderStaffList() → closeModal()

Edit staff
  openStaffModal('edit', staff) → user changes name → submitStaffModal()
  ↓ UPDATE in DB → update STAFF[] entry → renderStaffList() → closeModal()

Soft-delete
  showDeleteConfirm(staffId) → deleteConfirmId set
  ↓ confirm click → UPDATE is_active=false in DB → update STAFF[] entry → renderStaffList()
  ↓ cancel click  → deleteConfirmId = null → renderStaffList()
```

### Staff Card Render State

```
staff.is_active = true  → normal card, edit + delete buttons visible
staff.is_active = false → dimmed card, "غير نشط" badge, no delete button (already inactive)

deleteConfirmId === staff.id → card shows inline confirm/cancel row instead of action buttons
```

---

## `STAFF[]` Item Shape

```js
{
  id:         string,   // UUID
  name:       string,   // Display name
  is_active:  boolean,  // true = active, false = soft-deleted
  created_at: string    // ISO timestamp (for reference only, not displayed in this phase)
}
```

---

## PIN Hashing — No DB Entity Change

The `settings` table stores `pin_hash` (TEXT, 64-char SHA-256 hex). The dashboard reads this once on PIN submit and compares client-side. No writes to `settings` in this phase (PIN change is Phase 5).
