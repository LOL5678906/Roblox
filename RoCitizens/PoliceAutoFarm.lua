local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local FunctionLibrary = require(ReplicatedStorage.FunctionLibrary)
local PointTasks = FunctionLibrary.LoadModule("PointTasks")
local Interaction = ReplicatedStorage:WaitForChild("Relays").Crime.PoliceTaskInteraction

local AutoPoliceFarm = { Running = false }

local function FindTaskPoints()
    local points = {}
    local groups = rawget(PointTasks, "Groups")
    local police = groups and groups.Police

    if not police then
        return points
    end

    local function Scan(tbl, depth)
        if depth > 4 then
            return
        end
        for _, value in pairs(tbl) do
            local t = typeof(value)
            if t == "CFrame" then
                table.insert(points, value)
            elseif t == "Vector3" then
                table.insert(points, CFrame.new(value))
            elseif t == "Instance" and value:IsA("BasePart") then
                table.insert(points, value.CFrame)
            elseif t == "table" then
                Scan(value, depth + 1)
            end
        end
    end

    Scan(police, 0)
    return points
end

local function TaskTeleport()
    local points = FindTaskPoints()
    if #points == 0 then
        return false -- no task assigned yet
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    root.CFrame = points[1] + Vector3.new(0, 5, 0) -- offset up to avoid spawning inside geometry
    return true
end

local function TryComplete()
    local ok, success = pcall(function()
        return Interaction:InvokeServer("VehicleTicket")
    end)
    return ok and success == true
end

function AutoPoliceFarm.Start(retryInterval)
    if AutoPoliceFarm.Running then
        return false
    end
    AutoPoliceFarm.Running = true
    retryInterval = retryInterval or 5

    task.spawn(function()
        while AutoPoliceFarm.Running do
            local teleported = false
            local waited = 0

            while AutoPoliceFarm.Running and waited < 30 and not teleported do
                teleported = TaskTeleport()
                if not teleported then
                    task.wait(1)
                    waited += 1
                end
            end

            if not AutoPoliceFarm.Running then
                break
            end

            if teleported then
                task.wait(1) -- let client render settle before completing
                if TryComplete() then
                    local cooldown = 0
                    while AutoPoliceFarm.Running and cooldown < 65 do
                        task.wait(1)
                        cooldown += 1
                    end
                else
                    task.wait(retryInterval)
                end
            else
                task.wait(retryInterval)
            end
        end
    end)

    return true
end

function AutoPoliceFarm.Stop()
    AutoPoliceFarm.Running = false
end

-- AutoPoliceFarm.Start()
