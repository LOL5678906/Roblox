--[[ @author scriptalua(scriptalua) ]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Bullet = require(RS.Components.Weapon.Classes.Bullet)

local lp = Players.LocalPlayer
local FOV = 25

local function isEnemy(plr)
    if plr == lp then
        return false
    end
    local team = plr:GetAttribute("Team")
    local myteam = lp:GetAttribute("Team")
    -- ffa
    if workspace:GetAttribute("Gamemode") == "Deathmatch" then
        return team ~= "Spectators"
    end
    return team ~= nil and myteam ~= nil and team ~= myteam and team ~= "Spectators"
end

local function getHead(char)
    return char:FindFirstChild("Head") or char.PrimaryPart
end

local function getTarget(cam, origin, range)
    local best, bestAngle
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if isEnemy(plr) and char and not char:GetAttribute("Dead") then
            local head = getHead(char)
            if head then
                local offset = head.Position - origin
                local dist = offset.Magnitude
                if dist <= range and dist > 0 then
                    local angle = math.deg(math.acos(math.clamp(cam.CFrame.LookVector:Dot(offset.Unit), -1, 1)))
                    if angle <= FOV and (not bestAngle or angle < bestAngle) then
                        best, bestAngle = head, angle
                    end
                end
            end
        end
    end
    return best
end

local old
old =
    hookfunction(
    Bullet._performRaycast,
    function(self, spread)
        local result = old(self, spread)
        local cam = workspace.CurrentCamera
        if not cam then
            return result
        end
        local origin = cam.CFrame.Position
        local range = (self.Properties and self.Properties.Range) or 500
        local head = getTarget(cam, origin, range)
        if not head then
            return result
        end
        local dir = (head.Position - origin).Unit
        result.Direction = dir
        result.Distance = (head.Position - origin).Magnitude
        result.Hits = {
            {
                Position = head.Position,
                Instance = head,
                Material = "Plastic",
                Normal = -dir,
                Exit = false
            }
        }
        return result
    end
)
