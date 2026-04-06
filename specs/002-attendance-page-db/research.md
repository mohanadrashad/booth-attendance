# Research: Phase 2 — Attendance Page (DB Connected)

**Date**: 2026-04-05  
**Branch**: `002-attendance-page-db`

---

## 1. Loading Supabase JS in a Single HTML File (No Build Step)

**Decision**: Load the Supabase JS v2 client from jsDelivr CDN with a `<script>` tag in `<head>`, followed immediately by a `<script src="config.js">` tag. Initialize the client at the top of the inline `<script>` block.

```html
<head>
  <!-- existing tags ... -->
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <script src="config.js"></script>
</head>
```

```js
// Top of inline <script>
const _supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

**Rationale**: jsDelivr is highly available and caches aggressively. Loading in `<head>` (not `defer`/`async`) ensures the client is ready before the inline script runs. `config.js` must load after the CDN script but before the inline script.

**Alternatives considered**:
- Load via `<script type="module">` with an import map: Cleaner but requires a server (CORS blocks local file imports in some browsers); rejected for local-file compatibility.
- Bundle locally: Requires npm/Node; rejected — no build system.
- Load with `async` attribute: Risks a race condition where the inline script runs before Supabase loads; rejected.

---

## 2. Async Init Pattern for a Single-File App

**Decision**: Replace the synchronous `init()` call at page bottom with an `async init()` function, called via `document.addEventListener('DOMContentLoaded', init)`. The function runs three parallel queries (staff, active event, existing attendance) using `Promise.all`, then renders.

```js
async function init() {
  showLoading(true);
  try {
    const [staffResult, eventResult] = await Promise.all([
      _supabase.from('staff').select('id, name').eq('is_active', true).order('name'),
      _supabase.from('events').select('id, name, event_date').eq('is_active', true).single()
    ]);
    // handle errors, then load attendance for active event
    // ...
  } catch (e) {
    showError('حدث خطأ في الاتصال');
  } finally {
    showLoading(false);
  }
}
```

**Rationale**: `Promise.all` for staff + event runs them concurrently (saves ~300–500ms vs sequential). Attendance must load after the event ID is known, so it's a second `await` after the first batch resolves.

**Alternatives considered**:
- Sequential `await` for all three: Simpler but ~2× slower; rejected for performance.
- Top-level `await` in module script: Requires `type="module"`, which breaks local file loading in some browsers; rejected.

---

## 3. In-Memory State Shape After DB Migration

**Decision**: Keep `attendance` as a plain object cache keyed by `staffId` (UUID string), mirroring the DB but held in memory for fast UI re-renders. Add `currentEvent` and `STAFF` as module-level variables populated on init.

```js
let STAFF = [];          // [{ id: UUID, name: string }] — loaded from DB
let currentEvent = null; // { id: UUID, name: string, event_date: string } | null
let attendance = {};     // { [staffId: UUID]: { time, signature, timestamp, recordId } }
let currentStaffId = null;
```

**Rationale**: Keeping an in-memory cache avoids re-fetching the full attendance list from the DB on every check-in. The DB is the source of truth (populated on init, written on confirm); the in-memory cache is only for rendering speed.

**Alternatives considered**:
- Re-query DB on every render: Correct but slow (~300ms per card click); rejected.
- Remove in-memory state entirely: Would require async rendering; too complex for a single-file app; rejected.

---

## 4. UUID vs Integer Staff IDs

**Decision**: The existing `STAFF` array uses integer `id`s (`1, 2, 3...`); the DB uses UUIDs. No special migration is needed — `STAFF` is now loaded from the DB and uses UUID strings throughout. The `attendance{}` object is re-keyed from integers to UUID strings. All downstream functions (`openModal`, `renderStaff`, `confirmAttendance`) use the UUID string from the DB record directly.

**Rationale**: Since the hardcoded `STAFF` array is completely replaced, there is no legacy integer ID to preserve. Clean break.

**Impact**: `renderStaff()` still works identically — it iterates `STAFF` and looks up `attendance[s.id]`, which now uses UUID strings as keys instead of integers.

---

## 5. Confirming Attendance — Async Write Pattern

**Decision**: `confirmAttendance()` becomes `async`. It inserts the record to Supabase, then on success updates the in-memory `attendance{}` cache, closes the modal, re-renders, and shows the success toast. On error, it shows an error toast and does NOT update in-memory state (card stays non-interactive only on success).

```js
async function confirmAttendance() {
  if (!currentStaffId || !hasDrawn || !currentEvent) return;
  const sigData = canvas.toDataURL('image/png');
  const { data, error } = await _supabase.from('attendance').insert({
    staff_id: currentStaffId,
    event_id: currentEvent.id,
    signature_data: sigData
  }).select('id, checked_in_at').single();

  if (error) {
    showToast('❌ فشل تسجيل الحضور، حاول مرة أخرى');
    return;
  }
  // update in-memory cache
  const now = new Date(data.checked_in_at);
  const time = now.toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' });
  attendance[currentStaffId] = { time, signature: sigData, timestamp: data.checked_in_at, recordId: data.id };
  closeModal();
  renderStaff();
  updateStats();
  const staff = STAFF.find(s => s.id === currentStaffId);
  showToast(`✓ تم تسجيل حضور ${staff.name}`);
}
```

**Rationale**: Writing to DB first, updating UI second ensures the UI only reflects confirmed persisted state. Using `.select('id, checked_in_at').single()` returns the server-generated timestamp, which is used in the card display for accuracy.

**Alternatives considered**:
- Optimistic update (update UI first, roll back on error): Better UX but adds rollback complexity to a single-file app; deferred.
- Fire-and-forget (don't await): Risks showing success when the DB write actually failed; rejected.

---

## 6. Loading State Without a Framework

**Decision**: Add a single `<div id="loadingOverlay">` element inside `#staffList` and toggle its visibility via CSS class on the container. No new CSS — use the existing dark-theme variables.

```html
<div id="loadingOverlay" class="loading-overlay hidden">
  <span>جارٍ التحميل...</span>
</div>
```

```js
function showLoading(visible) {
  document.getElementById('loadingOverlay').classList.toggle('hidden', !visible);
  document.getElementById('staffList').classList.toggle('hidden', visible);
}
```

**Rationale**: Minimal DOM change, no framework. The existing `hidden` pattern (CSS `display: none`) is already used in the modal placeholder (`sigPlaceholder`).

---

## 7. Missing or Invalid Config Handling

**Decision**: Wrap the `createClient` call in a try/catch and add a guard at the top of `init()` that checks for the presence of `SUPABASE_URL` and `SUPABASE_ANON_KEY` globals before proceeding.

```js
if (typeof SUPABASE_URL === 'undefined' || typeof SUPABASE_ANON_KEY === 'undefined') {
  showFatalError('ملف الإعدادات مفقود. يرجى إنشاء ملف config.js');
  return;
}
```

**Rationale**: Without this guard, a missing `config.js` causes an uncaught ReferenceError that silently breaks the page. An Arabic error message guides the operator or developer.

---

## 8. Export Function — DB-Backed Report

**Decision**: `exportData()` reads from the in-memory `attendance{}` cache (which was hydrated from the DB on init and updated on each check-in). This means export is already DB-backed without any additional query, as long as the page was not refreshed mid-export after a crash. The event name from `currentEvent.name` replaces the hardcoded title.

**Rationale**: The in-memory cache is always a complete reflection of the DB for the current event (loaded on init, appended on each insert). A fresh DB query on export would add latency for no benefit.

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| Supabase CDN loading | `<script>` in `<head>`, before `config.js`, before inline script |
| Init pattern | `async init()` via DOMContentLoaded; staff + event fetched in parallel |
| State shape | `STAFF[]`, `currentEvent`, `attendance{}` (UUID-keyed) loaded from DB |
| ID migration | Integer IDs fully replaced by UUID strings from DB |
| Confirm write | Async insert → server timestamp → update cache on success only |
| Loading state | Single `loadingOverlay` div toggled by CSS class |
| Config guard | Check globals before init; show Arabic fatal error if missing |
| Export | Reads from in-memory cache (already DB-hydrated); no extra query |
