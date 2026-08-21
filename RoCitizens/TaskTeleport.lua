-- can use Instant Task complete when teleported btw (POLICE ONLY)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local FunctionLibrary = require(ReplicatedStorage.FunctionLibrary)
local PointTasks = FunctionLibrary.LoadModule("PointTasks")

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
        return false, "No active task point"
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false, "No character"
    end

    root.CFrame = points[1] + Vector3.new(0, 5, 0)
    return true
end

TaskTeleport()
