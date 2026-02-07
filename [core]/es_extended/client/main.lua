Core = {}
Core.Input = {}
Core.Events = {}

ESX.PlayerData = {}
ESX.PlayerLoaded = false
ESX.playerId = PlayerId()
ESX.serverId = GetPlayerServerId(ESX.playerId)

ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

CreateThread(function()
    while not Config.Multichar do
        Wait(100)

        if NetworkIsPlayerActive(ESX.playerId) then
            ESX.DisableSpawnManager()
            DoScreenFadeOut(0)
            Wait(500)
            TriggerServerEvent("esx:onPlayerJoined")
            break
        end
    end
end)

-- ===================================================================
-- PHASE 1: THE EMULATOR (COMPATIBILITY BRIDGE)
-- ===================================================================

-- 1. Listen for changes to 'esx_data' on the local player
AddStateBagChangeHandler('esx_data', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(bagName, key, value, _, replicated)
    -- Only process if data exists
    if not value then return end

    -- 2. Sync Local ESX Object (Update Memory)
    if ESX.PlayerData then
        ESX.PlayerData.money = value.money
        ESX.PlayerData.bank = value.bank
        ESX.PlayerData.job = value.job
        ESX.PlayerData.grade = value.grade
        ESX.PlayerData.group = value.group
    end

    -- 3. Fire Legacy Events (Backward Compatibility)
    -- This ensures old scripts (HUDs, Jobs) still work
    TriggerEvent('esx:setAccountMoney', 'money', value.money)
    TriggerEvent('esx:setAccountMoney', 'bank', value.bank)
    TriggerEvent('esx:setJob', value.job, value.grade)
end)

print("^2[Phase 1 Client]^7 Emulator Loaded: State Bag -> Event Bridge Active.")
