
-- The Emulator: Compatibility Bridge for Legacy Events
-- Listens to State Bag changes and fires legacy client events.

local function OnInventoryChange(bagName, key, value, _unused, replicated)
    if not value or not ESX.PlayerLoaded then return end
    
    -- Convert O(1) Map to Legacy Array
    local legacyInventory = {}
    for name, item in pairs(value) do
        if item.count > 0 then
            table.insert(legacyInventory, {
                name = name,
                count = item.count,
                label = item.label,
                weight = item.weight,
                usable = item.usable,
                rare = item.rare,
                canRemove = item.canRemove
            })
        end
    end

    -- Sort for consistency (Legacy ESX sorts by label)
    table.sort(legacyInventory, function(a, b)
        return a.label < b.label
    end)

    -- Update ESX.PlayerData locally
    ESX.PlayerData.inventory = legacyInventory

    -- Fire Legacy Event
    TriggerEvent('esx:setInventory', legacyInventory)
end

local function OnJobChange(bagName, key, value, _unused, replicated)
    if not value or not ESX.PlayerLoaded then return end
    
    -- Update ESX.PlayerData locally
    ESX.PlayerData.job = value

    -- Fire Legacy Event
    TriggerEvent('esx:setJob', value)
end

local function OnAccountsChange(bagName, key, value, _unused, replicated)
    if not value or not ESX.PlayerLoaded then return end

    -- Value is expected to be a Map: { money = 100, bank = 5000 }
    -- Legacy ESX.PlayerData.accounts is an Array: { {name="money", money=100}, ... }
    
    for accountName, accountMoney in pairs(value) do
        -- Find and update in Array
        local found = false
        for i = 1, #ESX.PlayerData.accounts do
            if ESX.PlayerData.accounts[i].name == accountName then
                ESX.PlayerData.accounts[i].money = accountMoney
                found = true
                -- Fire single account update event (Legacy behavior)
                TriggerEvent('esx:setAccountMoney', ESX.PlayerData.accounts[i])
                break
            end
        end
    end
end

-- Register Handlers
AddStateBagChangeHandler('inventory', 'player:' .. GetPlayerServerId(PlayerId()), OnInventoryChange)
AddStateBagChangeHandler('job', 'player:' .. GetPlayerServerId(PlayerId()), OnJobChange)
AddStateBagChangeHandler('accounts', 'player:' .. GetPlayerServerId(PlayerId()), OnAccountsChange)

-- Group Handler (Optional but good)
AddStateBagChangeHandler('group', 'player:' .. GetPlayerServerId(PlayerId()), function(bagName, key, value)
    if not value then return end
    ESX.PlayerData.group = value
    TriggerEvent('esx:setGroup', value)
end)

-- Initial State Force Trigger
-- Ensures HUDs that rely on update events (not just playerLoaded) get their data immediately.
RegisterNetEvent('esx:playerLoaded', function(xPlayer, isNew, skin)
    local state = LocalPlayer.state
    
    -- We assume state is ready because events.lua blocks until state.esx_loaded is true.
    
    -- Force Job Sync
    if state.job then
        TriggerEvent('esx:setJob', state.job)
    end
    
    -- Force Inventory Sync
    if state.inventory then
        -- We reuse the OnInventoryChange logic by mocking the call or duplicating minimal logic.
        -- Since we have the function, let's call it directly with a mock bagName/key
        OnInventoryChange(nil, nil, state.inventory, nil, nil)
    end
    
    -- Force Accounts Sync
    if state.accounts then
        OnAccountsChange(nil, nil, state.accounts, nil, nil)
    end
    
    -- Force Group Sync
    if state.group then
        TriggerEvent('esx:setGroup', state.group)
    end
end)

-- Task 2: Fix Phase 1 (The Missing Emulator)
-- esx_data handler for legacy compatibility
AddStateBagChangeHandler('esx_data', 'player:' .. GetPlayerServerId(PlayerId()), function(bagName, key, value, _unused, replicated)
    if not value or not ESX.PlayerLoaded then return end

    -- Job Check
    if ESX.PlayerData.job and value.job ~= ESX.PlayerData.job.name then
        TriggerEvent('esx:setJob', ESX.PlayerData.job)
    end

    -- Money/Bank Check
    local currentMoney, currentBank = 0, 0
    if ESX.PlayerData.accounts then
        for _, acc in ipairs(ESX.PlayerData.accounts) do
            if acc.name == 'money' then currentMoney = acc.money end
            if acc.name == 'bank' then currentBank = acc.money end
        end

        if value.money ~= currentMoney then
            for i, acc in ipairs(ESX.PlayerData.accounts) do
                if acc.name == 'money' then
                    ESX.PlayerData.accounts[i].money = value.money
                    TriggerEvent('esx:setAccountMoney', ESX.PlayerData.accounts[i])
                    break
                end
            end
        end

        if value.bank ~= currentBank then
            for i, acc in ipairs(ESX.PlayerData.accounts) do
                if acc.name == 'bank' then
                    ESX.PlayerData.accounts[i].money = value.bank
                    TriggerEvent('esx:setAccountMoney', ESX.PlayerData.accounts[i])
                    break
                end
            end
        end
    end
end)
