--[[ @author scriptalua(scriptalua) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local RS = game:GetService("ReplicatedStorage")
local sim = require(RS.Shared.GrenadeSimulator)

local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

local NADES = {
    ["HE Grenade"] = {},
    ["Flashbang"] = {},
    ["Smoke Grenade"] = {},
    ["Decoy Grenade"] = {},
    ["Molotov"] = { fire = true },
    ["Incendiary Grenade"] = { fire = true },
}

local COLOR = Color3.fromRGB(0, 255, 120)
local MAX_CALLS = 150
local DT = 1 / 60

local lines = {}
local dot = Drawing.new("Circle")
dot.Radius = 5
dot.Filled = true
dot.NumSides = 16
dot.Color = COLOR
dot.Visible = false

local function hide()
    for _, l in ipairs(lines) do
        l.Visible = false
    end
    dot.Visible = false
end

local function destroyAll()
    for _, l in ipairs(lines) do
        l:Remove()
    end
    table.clear(lines)
    dot:Remove()
end

local function getTrajectory()
    local char = lp.Character
    if not char or not char.PrimaryPart or char:GetAttribute("Dead") then
        return nil
    end

    local wname
    local eq = lp:GetAttribute("CurrentEquipped")
    if eq then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, eq)
        if ok and type(data) == "table" then
            wname = data.Name or data.Weapon
        end
    end

    local info = wname and NADES[wname]
    if not info then
        return nil
    end

    local throwType = "Far"
    local origin, dir = sim.calculateThrowParameters(camera.CFrame.Position, camera.CFrame.LookVector, throwType, 1)
    local state = sim.createInitialState(origin, dir, throwType, char.PrimaryPart.AssemblyLinearVelocity, 1, tick())

    local config = {
        restitution = 0.4,
        maxBounces = 20,
        radius = 0.5,
        fuseTime = nil,
        minimumFuseTime = info.fire and 0.1 or nil,
        explodeOnFloorImpact = info.fire or nil,
        rangeScale = 1,
        isNearThrow = false,
    }

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char, workspace:FindFirstChild("Debris"), camera }
    params.IgnoreWater = true

    local pts = { state.position }
    local endPos = state.position

    for _ = 1, MAX_CALLS do
        local res = sim.simulate(state, config, params, DT)
        state = res.state
        pts[#pts + 1] = state.position
        endPos = state.position

        for _, e in ipairs(res.events) do
            if e.type == "bounce" then
                pts[#pts + 1] = e.position
                endPos = e.position
            elseif e.type == "rest" or e.type == "fuse" or e.type == "floor_impact" then
                return pts, endPos
            end
        end

        if state.isAtRest then
            break
        end
    end

    return pts, endPos
end

RunService.RenderStepped:Connect(function()
    if not camera then
        camera = workspace.CurrentCamera
        hide()
        return
    end

    local pts, endPos = getTrajectory()
    if not pts or #pts < 2 then
        hide()
        return
    end

    local segs = #pts - 1

    while #lines < segs do
        local l = Drawing.new("Line")
        l.Thickness = 1.5
        l.Color = COLOR
        lines[#lines + 1] = l
    end

    for i = #lines, segs + 1, -1 do
        lines[i]:Remove()
        table.remove(lines, i)
    end

    local prev, prevOk
    for i = 1, segs do
        local l = lines[i]
        local a = pts[i]
        local b = pts[i + 1]

        if i == 1 or not prevOk then
            local s1, o1 = camera:WorldToViewportPoint(a)
            prev = Vector2.new(s1.X, s1.Y)
            prevOk = s1.Z > 0
        end

        local s2, o2 = camera:WorldToViewportPoint(b)
        local cur = Vector2.new(s2.X, s2.Y)
        local curOk = s2.Z > 0

        if prevOk and curOk and o2 then
            l.From = prev
            l.To = cur
            l.Visible = true
        else
            l.Visible = false
        end

        prev = cur
        prevOk = curOk
    end

    local s, o = camera:WorldToViewportPoint(endPos)
    if s.Z > 0 and o then
        dot.Position = Vector2.new(s.X, s.Y)
        dot.Visible = true
    else
        dot.Visible = false
    end
end)
