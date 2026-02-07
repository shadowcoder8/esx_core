# Phase 1 & 2 Architectural Fix Plan (Final v1.5)

## 1. Git Hygiene
- **Branch**: `fix/architectural-alignment` (Active).

## 2. Player Class Updates (`server/classes/player.lua`)
- **Constructor**: `self.isDirty = false` and `self.prioritySave = false` initialized.
- **Conflict Resolution**: Ensured `self.prioritySave` is present and no merge markers exist.

## 3. Save Logic Refactor (`server/functions.lua`)
- **Gate-Keeping**: `Core.SavePlayer` checks `if not xPlayer.isDirty then return end`.
- **Optimistic Locking**: `xPlayer.isDirty = false` set before MySQL query.
- **Error Recovery**: `xPlayer.isDirty = true` restored on failure.

## 4. State Bag Broadcast (`server/main.lua`)
- **Broadcast Timing**: `esx_data` state bag set at the **end** of `loadESXPlayer`.
- **Payload**: Includes `money`, `bank`, `job`, `group`.

## 5. Diagnostic Script (`server/modules/commands.lua`)
- **Command**: `/testphases`.
- **Checks**:
  - Phase 1: `esx_data` existence.
  - Phase 2: `isDirty` flag state.

## 6. Verification
- **Status**: Implementation complete. Ready for server-side testing.
