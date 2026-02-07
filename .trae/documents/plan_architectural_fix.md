# Phase 1 & 2 Architectural Fix Plan (Final v1.4)

## 1. Git Hygiene
- **Branch**: Create `fix/architectural-alignment` from the current state.

## 2. Player Class Updates (`server/classes/player.lua`)
- **Constructor Fix**: Initialize `self.isDirty = false` explicitly in `CreateExtendedPlayer`.
- **Setters Audit**: Ensure `setMoney`, `addMoney`, `removeMoney`, `setAccountMoney`, `addAccountMoney`, `removeAccountMoney`, `setJob`, `setGroup`, `addInventoryItem`, `removeInventoryItem`, `setInventoryItem`, `addWeapon`, `removeWeapon`, `addWeaponComponent`, `removeWeaponComponent`, `setWeaponTint`, `setCoords`, `setMeta`, `setName` all trigger `self.isDirty = true` (or call `Core.SavePlayer` for high-value items).
  - *Note*: Priority Saves are already implemented for high-value transactions.

## 3. Save Logic Refactor (`server/functions.lua`)
- **Gate-Keeping**: Modify `Core.SavePlayer` to check `xPlayer.isDirty`.
  - **Logic**:
    1. Check `if not xPlayer.isDirty then return end`.
    2. Set `xPlayer.isDirty = false` (Optimistic Locking) *before* the SQL query.
    3. In the MySQL callback, if the update fails (affectedRows != 1), revert `xPlayer.isDirty = true` to ensure retry.
  - **Reset**: The optimistic locking strategy (setting false before query) handles the reset requirement, while the error handler ensures data safety.

## 4. State Bag Broadcast (`server/main.lua`)
- **Broadcast Timing**: Move the `esx_data` state bag setting to the **absolute final line** of `loadESXPlayer`.
- **Payload Structure**:
  ```lua
  Player(playerId).state:set('esx_data', {
      money = xPlayer.getMoney(),
      bank = xPlayer.getAccount('bank').money,
      job = xPlayer.getJob().name,
      group = xPlayer.getGroup()
  }, true)
  ```
  - *Rationale*: Keeps payload light and ensures all metadata is fully loaded before broadcast.

## 5. Diagnostic Script Alignment
- **Action**: Search for and update the `/testphases` (or `checkrefactor`) command to specifically check `xPlayer.isDirty` (not `dirty` or other variants) to ensure the test accurately reflects the internal state.

## 6. Execution Steps
1.  **Git**: `git checkout -b fix/architectural-alignment`.
2.  **Class Constructor**: Edit `server/classes/player.lua`.
3.  **Save Logic**: Edit `server/functions.lua`.
4.  **State Bag**: Edit `server/main.lua`.
5.  **Diagnostic**: Search for and update the diagnostic command.
6.  **Verify**: Code review to ensure "isDirty" is consistently used and logic flows correctly.
