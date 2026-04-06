# Research: Phase 3 — Dashboard Core

**Date**: 2026-04-05  
**Branch**: `003-dashboard-core`

---

## 1. SHA-256 PIN Hashing — Web Crypto API (No Library Needed)

**Decision**: Use the browser's built-in `crypto.subtle.digest('SHA-256', data)` API to hash the PIN client-side before comparing against the stored hash. No external crypto library required.

```js
async function hashPin(pin) {
  const encoder = new TextEncoder();
  const data = encoder.encode(pin);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}
```

**Rationale**: `crypto.subtle` is available in all modern browsers (including mobile Safari) and requires no CDN load. The stored hash in the `settings` table is a hex-encoded SHA-256 string (64 chars), which is exactly what this function produces.

**Seed hash match**: The seed data stores `03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4` (SHA-256 of `'1234'`). This function produces the same value.

**Alternatives considered**:
- bcrypt via CDN: Overkill for a 4-digit PIN; adds a CDN dependency; rejected.
- Plain-text comparison: Never — PIN must not be stored or transmitted in plain text; rejected.
- SHA-256 via external library (CryptoJS): Unnecessary; Web Crypto is built in; rejected.

---

## 2. Session Persistence — `sessionStorage`

**Decision**: After a successful PIN verification, store a flag in `sessionStorage` (e.g., `sessionStorage.setItem('dashboard_auth', '1')`). On page load, check for this flag — if present, skip the PIN screen and show the dashboard directly. Logout clears `sessionStorage`.

```js
// On successful PIN verify:
sessionStorage.setItem('dashboard_auth', '1');

// On page load:
if (sessionStorage.getItem('dashboard_auth') === '1') {
  showDashboard();
} else {
  showPinScreen();
}

// On logout:
sessionStorage.removeItem('dashboard_auth');
showPinScreen();
```

**Rationale**: `sessionStorage` is cleared when the browser tab is closed, which is the right security boundary for this app (one device, shared use). It requires no server-side token management. Unlike `localStorage`, it does not persist across browser restarts.

**Alternatives considered**:
- `localStorage`: Persists indefinitely across browser sessions — too permissive for a shared device scenario; rejected.
- Cookie-based session: Requires a server to set/validate; not available in a static Netlify deployment; rejected.
- Re-verify PIN on every page load: Poor UX for a session that may span hours; rejected.

---

## 3. Staff CRUD — Supabase Anon Key with Permissive RLS

**Decision**: All staff CRUD operations (INSERT, UPDATE) use the same Supabase anon key as the attendance page. The security model relies on the PIN gate in the UI, not RLS row-level restrictions. The `staff` table RLS allows anon SELECT but blocks anon INSERT/UPDATE/DELETE (Phase 1 design). 

**Wait — this is a conflict with the spec assumption.** Re-reading Phase 1 schema: `staff` table RLS only grants anon `SELECT`. Anon INSERT/UPDATE is blocked. The spec assumption says "anon key is sufficient for staff writes" — this is **incorrect** based on the actual Phase 1 schema.

**Resolution**: Two options:
- **Option A**: Update the `staff` table RLS to allow anon INSERT/UPDATE (soft-delete = UPDATE). This keeps the single anon key model.
- **Option B**: Use the Supabase service-role key for dashboard writes. Requires adding a second key to `config.js`.

**Decision: Option A** — add anon INSERT and UPDATE policies to the `staff` table via a migration SQL file. This is simpler (no second key), acceptable for the security model (PIN gate provides the access control layer), and consistent with the attendance page's approach (anon INSERT on attendance is already allowed).

```sql
-- Add to supabase/migrations/001_staff_rls_dashboard.sql
CREATE POLICY "anon can insert staff"
  ON staff FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update staff"
  ON staff FOR UPDATE TO anon USING (true) WITH CHECK (true);
```

**Rationale**: The dashboard PIN gate is the security boundary. The Supabase anon key is already public (it's in `config.js` which is opened in the browser). RLS on top of PIN-gated client-side logic is defense in depth, but for this app's threat model (internal tool, booth operators), permissive anon RLS behind a PIN gate is acceptable.

**Alternatives considered**:
- Service-role key: More secure but requires the service-role key to be in a browser file (`config.js`), which exposes it to anyone who opens DevTools — strictly worse than anon key for browser apps; rejected.
- Supabase Edge Functions for writes: Overkill for this project; adds a build/deploy step; rejected.

---

## 4. Real-Time Search — Client-Side Filtering (No DB Query)

**Decision**: Load the complete staff list into memory once (on dashboard unlock). The search box filters the in-memory `STAFF` array on every `input` event and re-renders the filtered list. No Supabase query is made per keystroke.

```js
let STAFF = []; // loaded once on unlock
let searchQuery = '';

document.getElementById('searchInput').addEventListener('input', e => {
  searchQuery = e.target.value.trim();
  renderStaffList();
});

function renderStaffList() {
  const filtered = searchQuery
    ? STAFF.filter(s => s.name.includes(searchQuery))
    : STAFF;
  // render filtered...
}
```

**Rationale**: With ~50 staff members, client-side filtering is instant (<1ms) and produces no network latency. The spec requires results within 100ms of each keystroke — client-side easily meets this. Re-querying Supabase per keystroke would add 200–500ms latency and unnecessary load.

**Alternatives considered**:
- Debounced Supabase `ilike` query: Correct for thousands of records; unnecessary for 50; rejected.
- Supabase full-text search: Far more complex, no benefit at this scale; rejected.

---

## 5. Modal Pattern — Reuse Phase 2 Approach (Overlay + CSS Class)

**Decision**: Use the same modal overlay pattern as `booth-attendance.html` — a full-screen overlay div that's shown/hidden via `.active` CSS class. Two modals: one for add, one for edit (or one shared modal with different state).

**Decision: One shared modal** — set its title and pre-fill the name field dynamically. Track mode (`'add'` or `'edit'`) and the target `staffId` in module-level variables.

```js
let modalMode = null;  // 'add' | 'edit'
let editStaffId = null;

function openStaffModal(mode, staff = null) {
  modalMode = mode;
  editStaffId = staff ? staff.id : null;
  document.getElementById('modalTitle').textContent = mode === 'add' ? 'إضافة موظف' : 'تعديل الاسم';
  document.getElementById('staffNameInput').value = staff ? staff.name : '';
  document.getElementById('staffModal').classList.add('active');
  document.getElementById('staffNameInput').focus();
}
```

**Rationale**: One modal with shared logic is simpler than two identical modals. The only difference between add and edit is the pre-filled value and the submit action (INSERT vs UPDATE).

**Alternatives considered**:
- Two separate modals: More HTML, duplicated CSS, harder to maintain; rejected.
- Inline editing (edit in place on the card): Less discoverable in a mobile RTL layout; rejected.

---

## 6. Soft-Delete Confirmation — Native `confirm()` vs Custom Modal

**Decision**: Use a custom confirmation modal (not native `confirm()`), consistent with the signature confirmation approach in `booth-attendance.html`. The native `confirm()` dialog cannot be styled and breaks the dark-mode RTL experience.

A lightweight inline confirmation: clicking delete shows a confirmation row below the card with "تأكيد الحجب" and "إلغاء" buttons, no overlay required.

**Rationale**: Keeps the UI consistent with the dark-mode theme. Inline confirmation (no overlay) is lighter than a full modal for a single-step destructive action.

**Alternatives considered**:
- Native `confirm()`: Simple but unstyled, not RTL-aware, blocks the browser thread; rejected.
- Full overlay modal: Heavier than needed for a single confirm/cancel; rejected.

---

## 7. Dashboard File Structure — Mirror Phase 2 `<head>` Pattern

**Decision**: `dashboard.html` uses the identical `<head>` setup as `booth-attendance.html` (after Phase 2):
```html
<link href="https://fonts.googleapis.com/.../Tajawal..." rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="config.js"></script>
```

Same CSS variables (`:root` block), same dark-mode theme, same RTL direction. Staff cards in the dashboard use a similar layout to the attendance page cards but with action buttons added.

**Rationale**: Visual consistency between the two pages. Zero extra setup — the same CDN and config pattern already works.

---

## 8. Migration File for Staff RLS Patch

**Decision**: Create `supabase/migrations/001_staff_dashboard_rls.sql` with the two new policies (INSERT + UPDATE for anon on staff). This file is run manually in the Supabase SQL Editor, consistent with how schema.sql and seed.sql were applied.

```sql
-- supabase/migrations/001_staff_dashboard_rls.sql
-- Adds anon INSERT and UPDATE to staff table for dashboard CRUD.
-- Security relies on the PIN gate in dashboard.html.

CREATE POLICY "anon can insert staff"
  ON staff FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update staff"
  ON staff FOR UPDATE TO anon USING (true) WITH CHECK (true);
```

**Rationale**: Keeps the schema changes auditable and separate from the original schema.sql. Easy to apply and easy to reverse if the security model changes.

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| PIN hashing | `crypto.subtle.digest` (Web Crypto API, no library) |
| Session persistence | `sessionStorage` flag, cleared on tab close / logout |
| Staff writes (RLS) | New migration: anon INSERT + UPDATE on staff table |
| Search | Client-side in-memory filter on `input` event |
| Modal | Single shared modal, mode-switched (`add` / `edit`) |
| Delete confirmation | Inline confirm row on card (no overlay) |
| CSS/theme | Same dark-mode variables and Tajawal font as attendance page |
| Migration delivery | `supabase/migrations/001_staff_dashboard_rls.sql` (manual SQL Editor apply) |
