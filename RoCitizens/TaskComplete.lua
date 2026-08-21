-- POLICE ONLY

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Interaction = ReplicatedStorage:WaitForChild("Relays").Crime.PoliceTaskInteraction

local function InstantTaskComplete()
    local ok, success, err = pcall(function()
        return Interaction:InvokeServer("VehicleTicket")
    end)

    if not ok then
        return false, tostring(success)
    end

    return success, err
end

InstantTaskComplete()
