# JavaScript Function Contracts: Phase 3 — Dashboard Core

**Date**: 2026-04-05  
**Branch**: `003-dashboard-core`  
**File**: `dashboard.html` (new file)

---

## Authentication

### `async init()`

```
Precondition:  DOM loaded, config.js and Supabase CDN available
Steps:
  1. Guard: typeof SUPABASE_URL undefined → showFatalError(), return
  2. _supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  3. Check sessionStorage.getItem('dashboard_auth') === '1'
     YES → showDashboard() then loadStaff()
     NO  → showPinScreen()
Called by: DOMContentLoaded event
```

### `async submitPin()`

```
Inputs:    Value from #pinInput (4-digit string)
Steps:
  1. Guard: pin.length !== 4 → return (button should already be disabled)
  2. Disable submit button
  3. Fetch settings: SELECT pin_hash FROM settings WHERE id = 1
  4. If error/no row → showPinError('خطأ في الإعدادات — تحقق من seed.sql')
  5. hash = await hashPin(pin)
  6. hash === settings.pin_hash?
     YES → sessionStorage.setItem('dashboard_auth','1') → showDashboard() → loadStaff()
     NO  → showPinError('رمز PIN غير صحيح') → clear #pinInput → re-enable button
Postcondition (success): dashboard visible, STAFF[] loading
Postcondition (failure): PIN screen visible, error message shown
```

### `async hashPin(pin: string) → string`

```
Inputs:    4-character string (digits)
Output:    64-char lowercase hex SHA-256 digest
Uses:      crypto.subtle.digest('SHA-256', TextEncoder.encode(pin))
Pure function — no side effects
```

### `logout()`

```
Steps:
  1. sessionStorage.removeItem('dashboard_auth')
  2. showPinScreen()
  3. Clear #pinInput
```

---

## UI State

### `showPinScreen()`

```
Effect: #pinScreen visible, #dashboard hidden
        #pinInput cleared, #pinError hidden
```

### `showDashboard()`

```
Effect: #pinScreen hidden, #dashboard visible
```

### `showPinError(message: string)`

```
Effect: #pinError element text set to message, made visible
        Called on wrong PIN or settings fetch error
```

### `showFatalError(message: string)`

```
Effect: Replaces page content with Arabic error message
        Called when config.js is missing
```

---

## Staff List

### `async loadStaff()`

```
Steps:
  1. Fetch: SELECT id, name, is_active, created_at FROM staff ORDER BY name
  2. On error → show error message in staff list area, return
  3. STAFF = result.data
  4. renderStaffList()
Called by: showDashboard() (after PIN unlock and on session restore)
```

### `renderStaffList()`

```
Inputs:    Reads STAFF[] and searchQuery globals
Effect:    Re-renders #staffList container
           If searchQuery → filters STAFF by name.includes(searchQuery)
           If STAFF empty after filter → shows empty state message
           Each card: name, status badge, edit button, delete/confirm area
Pure render — no DB calls
```

---

## Staff Modal (shared add/edit)

### `openStaffModal(mode: 'add'|'edit', staff?: StaffRecord)`

```
Inputs:    mode — determines title and pre-fill
           staff — required when mode = 'edit'
Steps:
  1. modalMode = mode; editStaffId = staff?.id ?? null
  2. Set #modalTitle text
  3. #staffNameInput.value = mode==='edit' ? staff.name : ''
  4. Show #staffModal (.active class)
  5. Focus #staffNameInput
```

### `closeStaffModal()`

```
Steps:
  1. #staffModal.classList.remove('active')
  2. modalMode = null; editStaffId = null
  3. Clear #staffNameInput, #modalError
```

### `async submitStaffModal()`

```
Precondition: modalMode is 'add' or 'edit'
Steps:
  1. name = #staffNameInput.value.trim()
  2. Guard: name.length === 0 → show #modalError('يرجى إدخال الاسم'), return
  3. Disable submit button
  4. If modalMode === 'add':
       INSERT INTO staff (name) VALUES (name) RETURNING *
       On success → push result to STAFF[], renderStaffList(), closeStaffModal()
  5. If modalMode === 'edit':
       UPDATE staff SET name=$name WHERE id=$editStaffId RETURNING *
       On success → update STAFF[] entry, renderStaffList(), closeStaffModal()
  6. On error → show #modalError('فشل الحفظ، حاول مرة أخرى') → re-enable button
```

---

## Soft-Delete

### `showDeleteConfirm(staffId: string)`

```
Steps:
  1. deleteConfirmId = staffId
  2. renderStaffList() — card for staffId renders inline confirm UI
```

### `cancelDelete()`

```
Steps:
  1. deleteConfirmId = null
  2. renderStaffList()
```

### `async confirmDelete(staffId: string)`

```
Steps:
  1. UPDATE staff SET is_active=false WHERE id=staffId
  2. On success → update STAFF[] entry (is_active=false), deleteConfirmId=null, renderStaffList()
  3. On error → show toast error, deleteConfirmId=null, renderStaffList()
Postcondition: Staff entry has is_active=false in DB and in STAFF[] cache
               Historical attendance records untouched
```

---

## Search

### (inline event listener on #searchInput)

```
Event:  'input'
Steps:
  1. searchQuery = e.target.value.trim()
  2. renderStaffList()
No DB call — pure client-side filter
```
