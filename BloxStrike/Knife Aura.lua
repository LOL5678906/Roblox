--[[ @author scriptalua(scriptalua) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local RS = game:GetService("ReplicatedStorage")
local WeaponsDB = RS.Database.Custom.Weapons
local Remotes = require(RS.Database.Security.Remotes)
local CharacterResolver = require(RS.Components.Common.CharacterResolver)
local ReplicateCharacterAction = require(RS.Components.Common.ReplicateCharacterAction)

local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FOV = 180
local MAX_RANGE = 8 -- dosen't matter, wont work outside 6 studs

local function equippedData()
    local eq = lp:GetAttribute("CurrentEquipped")
    if not eq then return nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, eq)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local function knifeInfo()
    local d = equippedData()
    if not d then return nil end
    local name = d.Name or d.Weapon
    local mod = name and WeaponsDB:FindFirstChild(name)
    if not mod then return nil end
    local ok, props = pcall(require, mod)
    if not ok or type(props) ~= "table" then return nil end
    if not props.FireRate or not props.Range then return nil end
    if props.Range > MAX_RANGE then return nil end
    return props, d.Identifier
end

local function isEnemyChar(char)
    local plr = CharacterResolver.getPlayerFromCharacter(char)
    if not plr or plr == lp then return false end
    if char:GetAttribute("Dead") then return false end
    if plr:GetAttribute("Team") == "Spectators" then return false end
    -- ffa
    if workspace:GetAttribute("Gamemode") == "Deathmatch" then
        return true
    end
    local myteam = lp:GetAttribute("Team")
    return myteam ~= nil and plr:GetAttribute("Team") ~= myteam
end

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
visParams.IgnoreWater = true

local function findTarget(range)
    local origin = camera.CFrame.Position
    local best, bestDist

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if plr ~= lp and char and char.PrimaryPart and isEnemyChar(char) then
            local part = char.PrimaryPart
            local offset = part.Position - origin
            local dist = offset.Magnitude

            if dist <= range + 3 then
                visParams.FilterDescendantsInstances = { lp.Character, workspace:FindFirstChild("Debris") or workspace }
                local blocked = workspace:Raycast(origin, offset, visParams)
                local hitModel = blocked and blocked.Instance:FindFirstAncestorOfClass("Model")
                if not blocked or hitModel == char then
                    best, bestDist = part, dist
                end
            end
        end
    end

    return best, bestDist
end

local function isBehind(victimPart)
    local myRoot = lp.Character and lp.Character.PrimaryPart
    if not myRoot then return false end
    local dot = victimPart.CFrame.LookVector:Dot((myRoot.Position - victimPart.Position).Unit)
    return math.deg(math.acos(math.clamp(dot, -1, 1))) > 100
end

local lastSwing = 0

RunService.Heartbeat:Connect(function()
    if not camera then
        camera = workspace.CurrentCamera
        return
    end

    local char = lp.Character
    if not (char and not char:GetAttribute("Dead")) then return end
    if lp:GetAttribute("IsDefusingBomb") == true then return end

    local props, id = knifeInfo()
    if not props then return end

    local now = tick()
    if now - lastSwing < props.FireRate * 0.9 then return end

    local range = props.Range
    local target, dist = findTarget(range)
    if not target then return end

    lastSwing = now

    local pos = target.Position
    local dir = (pos - camera.CFrame.Position).Unit
    local attackName = isBehind(target) and "BackStab" or ("Swing" .. math.random(1, 2))

    Remotes.Melee.MeleeAttack.Send({
        Direction = camera.CFrame.LookVector * range,
        Material = target.Material.Name,
        Distance = math.min(dist, range),
        Instance = target,
        Position = pos,
        Normal = -dir,
        MeleeAttack = attackName,
        Identifier = id,
    })

    ReplicateCharacterAction(attackName == "BackStab" and "BackStab" or attackName)
end)
