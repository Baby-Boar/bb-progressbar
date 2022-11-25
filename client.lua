-- Global variables

local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Stores whether last progress bar process finished successfully
local Finished = false

-- Stores whether progress bar process is still active
local IsActive = false

-- Utils
function isActive()
    return IsActive
end
exports("isActive", isActive)

-- Core functions

-- Stops background iteration and whatever else needs to be done on finish
function finish()
    -- Server-specific event
    TriggerServerEvent('v-interaction:SetInteractionBlocked', false)
    IsActive = false
end

-- Sends a message to NUI that everything should stop, also stops background process
function interrupt()
    SendNUIMessage({
        type = "Interrupt"
    })
    finish()
end
exports("interrupt", interrupt)

-- Function that starts our progress bar, can  be configured in few different ways:
--
-- [duration] - How long should progress bar take - in ms
-- [title] - String shown on progress bar
-- [multiplier] - Multiplier for progress bar duration; I like to keep it as a
--                separate parameter, so that duration is (almost) always constant value 
-- [settings] - expects fields like
--              [maxDistance] - number | max distance that player can move since start of progress bar
--              [onTickCb] - () -> bool | function that's called every tick and returns whether
--                           progress bar should continue
--
-- It's worth noting that this function is synchronous; if you prefer async method
-- please use CreateThread provided by cfx or use event ['taskbar:start']
--
function start(duration, title, multiplier, settings)
    if IsActive() then
        return false
    end
    -- Server-specific event
    TriggerServerEvent('v-interaction:SetInteractionBlocked', true)
    
    Finished = false
    IsActive = true

    SendNUIMessage({
        type = "StartTimer",
        duration = duration,
        multiplier = multiplier,
        title = title
    })

    local maxDistance = settings.maxDistance or false
    local startCoords = GetEntityCoords(PlayerPedId())

    -- Background process that listens if progress should be interrupted
    while isActive() do
        Citizen.Wait(0)
        local distance = not maxDistance or GetDistanceBetweenCoords(
            GetEntityCoords(PlayerPedId()),
            startCoords,
            true
        )
        if (maxDistance and distance > maxDistance) then
            ESX.ShowNotification("You've gone too far!")
            interrupt()
        end
        if settings.perTickCb then
            if not settings.perTickCb() then
                interrupt()
            end
        end
    end

    return Finished
end
exports("start", start)

-- Events
-- Just here to provide async way to call exposed functions

RegisterNetEvent('taskbar:start', start)
RegisterNetEvent('taskbar:interrupt', interrupt)

-- NUI Callbacks

-- This function is called whenever progress bar reaches 100%
RegisterNUICallback("end", function(data, cb)
    Finished = data.finished
    finish()
end)