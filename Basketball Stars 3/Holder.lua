-- [[ stacktrace45 | Last updated 03/12/2026 ]] --

local repo = "https://raw.githubusercontent.com/LOL5678906/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

--// Services \\--
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

--// Lib stuff \\--
local Options = Library.Options
local Toggles = Library.Toggles

--// Window \\--
local Window = Library:CreateWindow({
    Title = "LOOEJ",
    Footer = "Basketball Stars 3 | By stacktrace45 | Open source | Discord : discord.gg/NxbdayKh",
    Icon = 14523252412,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

--// Tabs \\--
local Tabs = {
    Shooting = Window:AddTab("Shooting", "target"),
    Defense = Window:AddTab("Defense", "shield"),
    Movement = Window:AddTab("Movement", "zap"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "menu"),
    Info = Window:AddTab("Info", "info"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

--// State \\--
local autoTimeMethod = "Legit"
local autoTimeEnabled = false
local dunkChangerEnabled = false
local dunkAnimation = "Behind"
local autoStealEnabled = false
local teamCheck = true
local showIndicator = true
local stealRange = 1.5
local stealAnimation = false
local walkspeedEnabled = false
local walkspeedValue = 8.25
local autoStealIndicator = nil
local antiKnockback = false
local antiKnockConnection = nil
local oldKnockNamecall = nil
local staminaConnection = nil
local autoSwitchConnection = nil

--// Auto time \\--
local namecallHook = nil
local tweenConnections = {}
local autoTimeNamecallActive = false
local visualConnection = nil

--// helpers \\--
local function disconnectTween()
    for _, conn in pairs(tweenConnections) do
        conn:Disconnect()
    end
    tweenConnections = {}
end

local function disconnectNamecall()
    if namecallHook then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = namecallHook
        setreadonly(mt, true)
        namecallHook = nil
        autoTimeNamecallActive = false
    end
end

local function disconnectVisual()
    if visualConnection then
        visualConnection:Disconnect()
        visualConnection = nil
    end
end

--// Legit auto time \\--
local function setupTween()
    disconnectNamecall()
    disconnectVisual()
    local vals = getgenv().scriptValues or require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BallValues"))
    local funcs = getgenv().scriptFunctions or require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BallFunctions"))

    local function bind(t)
        table.insert(tweenConnections, t.Completed:Connect(function()
            if autoTimeEnabled and vals.holding then
                funcs.shoot()
            end
        end))
    end

    -- bind to all shot types
    bind(vals.jumpshotTween)
    bind(vals.layupTween)
    bind(vals.movingTween)
    bind(vals.dunkTween)
end

--// No bar \\--
local function setupNamecall()
    disconnectTween()
    disconnectVisual()
    if autoTimeNamecallActive then return end
    autoTimeNamecallActive = true

    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    if not namecallHook then
        namecallHook = mt.__namecall
    end

    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        if autoTimeEnabled and getnamecallmethod() == "FireServer" and tostring(self) == "BallEvent" and (args[2] == "shoot" or args[2] == "dunk") then
            args[3] = 1 -- perfect timing, dont change
            return namecallHook(self, unpack(args))
        end
        return namecallHook(self, ...)
    end)

    setreadonly(mt, true)
end

--// Auto bar \\--
local function setupVisual()
    disconnectTween()
    disconnectNamecall()

    local scriptValues
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "shootingGui") and rawget(v, "move") then
            scriptValues = v
            break
        end
    end

    visualConnection = RunService.RenderStepped:Connect(function()
        if autoTimeEnabled and scriptValues and scriptValues.shootingGui and scriptValues.shootingGui.Enabled and scriptValues.move then
            scriptValues.move.Size = UDim2.new(0.8, 0, 0.975, 0)
        end
    end)
end

--// Shooting Tab \\--
local ShootingLeft = Tabs.Shooting:AddLeftGroupbox("Auto Time", "target")

ShootingLeft:AddDropdown("AutoTimeMethod", {
    Values = {"Legit", "No Bar", "Auto Bar"},
    Default = autoTimeMethod,
    Text = "Auto Time Method",
    Callback = function(v)
        autoTimeMethod = v
        if autoTimeEnabled then
            if v == "Legit" then
                setupTween()
            elseif v == "No Bar" then
                setupNamecall()
            else
                setupVisual()
            end
        end
    end
})

ShootingLeft:AddToggle("AutoTime", {
    Text = "Auto Time",
    Default = autoTimeEnabled,
    Callback = function(v)
        autoTimeEnabled = v
        if v then
            if autoTimeMethod == "Legit" then
                setupTween()
            elseif autoTimeMethod == "No Bar" then
                setupNamecall()
            else
                setupVisual()
            end
        else
            disconnectTween()
            disconnectNamecall()
            disconnectVisual()
        end
    end
})

local ShootingRight = Tabs.Shooting:AddRightGroupbox("Shot Modifiers", "crosshair")

--// Hides the shot meter \\--
ShootingRight:AddButton({
    Text = "No Shot Meter",
    Func = function()
        local sg = Players.LocalPlayer.Character.HumanoidRootPart:WaitForChild("ShootingGui")
        sg.Enabled = false
        sg:GetPropertyChangedSignal("Enabled"):Connect(function()
            if sg.Enabled then
                sg.Enabled = false
            end
        end)
    end
})

--// Makes moving shots easier ( Credit: SeymourButtsIsAPeepingTom ) luraph causes this to crash \\--
ShootingRight:AddButton({
    Text = "Easier Moving Shots",
    Func = function()
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()

            if method == "FireServer" and self.Name == "BallEvent" and args[2] == "shoot" then
                if type(args[6]) == "table" then
                    args[5] = 0 -- ??????
                    args[6] = 1
                end
                return old(self, unpack(args))
            end

            return old(self, ...)
        end)
    end
})

--// High arc \\--
ShootingRight:AddButton({
    Text = "High Shot Arc",
    Func = function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local nc = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local a = {...}
            if getnamecallmethod() == "FireServer" and tostring(self) == "BallEvent" and typeof(a[6]) == "table" and typeof(a[6][2]) == "Vector3" then
                a[6][2] = Vector3.new(a[6][2].X, 35, a[6][2].Z) -- 35 arc max?
            end
            return nc(self, unpack(a))
        end)
        setreadonly(mt, true)
    end
})

--// Dunk Settings \\--
local DunkSettings = Tabs.Shooting:AddLeftGroupbox("Dunk Settings", "zap")

DunkSettings:AddToggle("DunkChanger", {
    Text = "Dunk Changer",
    Default = dunkChangerEnabled,
    Callback = function(v)
        dunkChangerEnabled = v
    end
})

DunkSettings:AddDropdown("DunkAnimation", {
    Values = {"2 Hand", "Tomahawk", "1 Hand", "Windmill", "Between", "Behind", "180", "Under", "360"},
    Default = dunkAnimation,
    Text = "Dunk Animation",
    Callback = function(v)
        dunkAnimation = v
    end
})

--// patch dunk range \\--
DunkSettings:AddToggle("UnlimitedDunkRange", {
    Text = "Unlimited Dunk Range",
    Default = false,
    Callback = function(v)
        local f = require(ReplicatedStorage.Modules.Functions).magXZ
        local c = debug.getconstants(f)
        for i, val in c do
            if val == "X" or val == "Z" or val == "Y" then
                debug.setconstant(f, i, v and "Y" or (val == "Y" and (i % 2 == 0 and "Z" or "X") or val))
            end
        end
    end
})

--// Dunk Changer \\--
local chr = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local hum = chr:WaitForChild("Humanoid")

--// Dunk anim ids \\--
local ids = {
    ["2 Hand"] = "rbxassetid://16792383527",
    ["Tomahawk"] = "rbxassetid://115440095914436",
    ["1 Hand"] = "rbxassetid://18998519353",
    ["Windmill"] = "rbxassetid://106278649589240",
    ["Between"] = "rbxassetid://74345936965111",
    ["Behind"] = "rbxassetid://120055472811741",
    ["180"] = "rbxassetid://95017863158093",
    ["Under"] = "rbxassetid://108988611725506",
    ["360"] = "rbxassetid://72310933284051"
}

--// Swaps dunk anim every frame if dunk changer is on \\--
RunService.Heartbeat:Connect(function()
    if not dunkChangerEnabled then return end
    for _, v in ipairs(hum:GetPlayingAnimationTracks()) do
        for _, id in pairs(ids) do
            if v.Animation.AnimationId == id and id ~= ids[dunkAnimation] then
                v:Stop()
                v:Destroy()
                local a = Instance.new("Animation")
                a.AnimationId = ids[dunkAnimation]
                local track = hum:LoadAnimation(a)
                track:Play()
                track:AdjustSpeed(1.2)
                return
            end
        end
    end
end)

--// Defense Tab \\--
local DefenseLeft = Tabs.Defense:AddLeftGroupbox("Defense", "shield")

DefenseLeft:AddToggle("AutoSteal", {
    Text = "Auto Steal",
    Default = autoStealEnabled,
    Callback = function(v)
        autoStealEnabled = v
        if not v and autoStealIndicator then
            autoStealIndicator:Destroy()
            autoStealIndicator = nil
        end
    end
})

DefenseLeft:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = teamCheck,
    Callback = function(v)
        teamCheck = v
    end
})

DefenseLeft:AddToggle("ShowIndicator", {
    Text = "Show Indicator",
    Default = showIndicator,
    Callback = function(v)
        showIndicator = v
        if not v and autoStealIndicator then
            autoStealIndicator:Destroy()
            autoStealIndicator = nil
        end
    end
})

DefenseLeft:AddToggle("StealAnimation", {
    Text = "Steal Animation",
    Default = stealAnimation,
    Callback = function(v)
        stealAnimation = v
    end
})

DefenseLeft:AddSlider("StealRange", {
    Text = "Steal Range",
    Default = stealRange,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        stealRange = v
    end
})

--// Local player stuff \\--
local p = Players.LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
local lastStealTime = 0

--// Auto steal \\--
RunService.RenderStepped:Connect(function()
    if not autoStealEnabled then
        if autoStealIndicator then
            autoStealIndicator:Destroy()
            autoStealIndicator = nil
        end
        return
    end

    local targetBall = nil
    local currentTime = tick()
    local ball = workspace:FindFirstChild("Balls") and workspace.Balls:FindFirstChild("Ball")

    -- single ball check
    if ball and (ball.Position - h.Position).Magnitude <= stealRange and currentTime - lastStealTime >= 0.5 then
        local ballOwner = ball:FindFirstChild("Player") and ball.Player.Value
        local shouldStealBall = true
        if teamCheck and ballOwner then
            shouldStealBall = ballOwner.Team ~= p.Team
        end
        if shouldStealBall then
            ReplicatedStorage:WaitForChild("BallEvent"):FireServer(ball, "steal")
            lastStealTime = currentTime
            if showIndicator then
                targetBall = ball
            end
        end
    end

    -- all balls check
    for _, b in pairs(workspace.Balls:GetChildren()) do
        if b:IsA("BasePart") and b:FindFirstChild("Player") then
            local plr = b.Player.Value
            if plr then
                local inRange = (b.Position - h.Position).Magnitude <= stealRange
                local shouldSteal = true
                if teamCheck then
                    shouldSteal = plr.TeamColor ~= p.TeamColor
                end
                if shouldSteal and inRange and currentTime - lastStealTime >= 0.5 then
                    ReplicatedStorage:WaitForChild("BallEvent"):FireServer(b, "steal")
                    lastStealTime = currentTime
                end
                if stealAnimation and shouldSteal and inRange then
                    local humChar = c:FindFirstChildOfClass("Humanoid")
                    if humChar then
                        -- pick left or right anim based on ball position
                        local animId = b.Position.X > h.Position.X and "rbxassetid://16190100758" or "rbxassetid://16190106253"
                        local anim = Instance.new("Animation")
                        anim.AnimationId = animId
                        humChar:LoadAnimation(anim):Play()
                    end
                end
                if showIndicator and inRange and shouldSteal then
                    targetBall = b
                end
            end
        end
    end

    -- green ball indicator (enjoy skidding this)
    if showIndicator then
        if targetBall then
            if not autoStealIndicator then
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 1, 1)
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 0.7
                part.Color = Color3.new(0, 1, 0)
                part.Shape = Enum.PartType.Ball
                autoStealIndicator = part
            end
            autoStealIndicator.Position = targetBall.Position
            autoStealIndicator.Parent = workspace
        elseif autoStealIndicator then
            autoStealIndicator:Destroy()
            autoStealIndicator = nil
        end
    end
end)

--// Auto contest - presses G when plr with ball is shooting near you \\--
DefenseLeft:AddToggle("AutoContest", {
    Text = "Auto Contest",
    Default = false,
    Callback = function(Value)
        if Value then
            if UserInputService.TouchEnabled then
                -- mobile version uses fireserver instead of keypress
                local rm = ReplicatedStorage:WaitForChild("Modules")
                local fm = require(rm:WaitForChild("Functions"))
                local be = ReplicatedStorage:WaitForChild("BallEvent")
                local dunkIds = {
                    ["16792383527"] = true,
                    ["115440095914436"] = true,
                    ["18998519353"] = true,
                    ["106278649589240"] = true,
                    ["74345936965111"] = true,
                    ["120055472811741"] = true,
                    ["95017863158093"] = true,
                    ["108988611725506"] = true,
                    ["72310933284051"] = true
                }
                task.spawn(function()
                    while task.wait() do
                        local char = p.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local ball = fm.findNearestBall(char.HumanoidRootPart.Position)
                            if ball and ball:FindFirstChild("Player") and ball:FindFirstChild("State") then
                                local bp = ball.Player.Value
                                if bp and bp ~= p and not fm.sameTeam(bp, p) then
                                    local dist = (ball.Position - char.HumanoidRootPart.Position).Magnitude
                                    local isDunking = false
                                    if bp.Character and bp.Character:FindFirstChildOfClass("Humanoid") then
                                        for _, track in pairs(bp.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                                            if dunkIds[track.Animation.AnimationId:match("%d+$")] then
                                                isDunking = true
                                                break
                                            end
                                        end
                                    end
                                    if dist <= 9 and (ball.State.Value == "Shooting" or isDunking) then
                                        be:FireServer(nil, "guarding", true)
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                -- pc version, presses G key when enemy shooting anim detected
                local contestIds = {["15625460755"] = true, ["15640551795"] = true, ["15640621238"] = true, ["15933297660"] = true, ["15933244201"] = true, ["16792383527"] = true}
                local pressing = false

                RunService.Heartbeat:Connect(function()
                    if not c or not c:FindFirstChild("HumanoidRootPart") then return end
                    local shouldPress = false
                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChildOfClass("Humanoid") and v.Team ~= p.Team then
                            local d = (c.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                            if d <= 8 then
                                local enemyLookVector = v.Character.HumanoidRootPart.CFrame.LookVector
                                local directionToPlayer = (c.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Unit
                                local dotProduct = enemyLookVector:Dot(directionToPlayer)
                                if dotProduct > -0.3 then
                                    for _, t in pairs(v.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                                        if contestIds[t.Animation.AnimationId:match("%d+$")] then
                                            shouldPress = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if shouldPress and not pressing then keypress(0x47); pressing = true
                    elseif not shouldPress and pressing then keyrelease(0x47); pressing = false end
                end)
            end
        end
    end
})

--// Block Settings \\--
local DefenseRight = Tabs.Defense:AddRightGroupbox("Block Settings", "hand")

--// Auto block - presses space when plr shooting anim plays near you \\--
DefenseRight:AddToggle("AutoBlock", {
    Text = "Auto Block",
    Default = false,
    Callback = function(v)
        if v then
            local blockIds = {
                ["15625460755"] = true,
                ["15640551795"] = true,
                ["15640621238"] = true,
                ["15933297660"] = true,
                ["15933244201"] = true,
                ["16792383527"] = true
            }
            RunService.Heartbeat:Connect(function()
                if not c or not c:FindFirstChild("HumanoidRootPart") then return end
                local hm = c:FindFirstChildOfClass("Humanoid")
                if not hm then return end
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= p and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Team ~= p.Team then
                        if (c.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude <= 6.5 then
                            for _, t in pairs(plr.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                                if blockIds[t.Animation.AnimationId:match("%d+$")] then
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

local DefenseUtils = Tabs.Defense:AddRightGroupbox("Defensive Utilities", "wrench")

DefenseUtils:AddButton({
    Text = "No Steal Cooldown",
    Func = function()
        local vals = require(Players.LocalPlayer.PlayerScripts.BallValues)
        spawn(function()
            while wait() do
                if vals.currentAnim == "Steal" then
                    vals.defensiveCooldown = false
                end
            end
        end)
    end
})

--// Movement Tab \\--
local MovementLeft = Tabs.Movement:AddLeftGroupbox("Speed", "zap")
local currtween = nil

--// tween based walkspeed (cant change directly with ws) \\--
MovementLeft:AddToggle("Walkspeed", {
    Text = "Walkspeed",
    Default = walkspeedEnabled,
    Callback = function(v)
        walkspeedEnabled = v
        if v then
            RunService.Heartbeat:Connect(function()
                if not walkspeedEnabled then return end
                local char = Players.LocalPlayer.Character
                if not char then return end
                local hroot = char:FindFirstChild("HumanoidRootPart")
                local humWalk = char:FindFirstChild("Humanoid")
                if not hroot or not humWalk then return end
                local mv = humWalk.MoveDirection
                if mv.Magnitude > 0 then
                    if currtween then
                        currtween:Cancel()
                    end
                    local tpos = hroot.CFrame.Position + mv * walkspeedValue
                    currtween = TweenService:Create(hroot, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {CFrame = CFrame.new(tpos, tpos + hroot.CFrame.LookVector)})
                    currtween:Play()
                else
                    if currtween then
                        currtween:Cancel()
                        currtween = nil
                    end
                end
            end)
        else
            if currtween then
                currtween:Cancel()
                currtween = nil
            end
        end
    end
})

MovementLeft:AddSlider("WalkspeedValue", {
    Text = "Walkspeed Value",
    Default = walkspeedValue,
    Min = 1,
    Max = 20,
    Rounding = 2,
    Callback = function(v)
        walkspeedValue = v
    end
})

--// Handles Settings \\--
local MovementRight = Tabs.Movement:AddRightGroupbox("Handles", "move")
local handlesSpeedValue = 16.25

MovementRight:AddToggle("HandlesSpeed", {
    Text = "Handles Speed Changer",
    Default = false,
    Callback = function(v)
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.handlesSpeed = v and handlesSpeedValue or 16.25
    end
})

MovementRight:AddSlider("HandlesSpeedValue", {
    Text = "Handles Speed",
    Default = 16.25,
    Min = 10,
    Max = 25,
    Rounding = 2,
    Callback = function(v)
        handlesSpeedValue = v
        require(ReplicatedStorage.Modules.Values).baseSliders.handlesSpeed = v
    end
})

local layupSpeedValue = 12.5

MovementRight:AddToggle("LayupGlide", {
    Text = "Layup Glide Changer",
    Default = false,
    Callback = function(v)
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.layupSpeed = v and layupSpeedValue or 12.5
        a.sliders.layupSpeed = v and layupSpeedValue or 12.5
    end
})

MovementRight:AddSlider("LayupGlideSpeed", {
    Text = "Layup Glide Speed",
    Default = 12.5,
    Min = 1,
    Max = 25,
    Rounding = 2,
    Callback = function(v)
        layupSpeedValue = v
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.layupSpeed = v
        a.sliders.layupSpeed = v
    end
})

--// Switches dribble hand away from the defender automatically \\--
MovementRight:AddToggle("AutoSwitchHands", {
    Text = "Auto Switch Hands",
    Default = false,
    Callback = function(v)
        if v then
            local playerScripts = p:WaitForChild("PlayerScripts")
            local scriptValues = require(playerScripts:WaitForChild("BallValues"))
            local functionModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Functions"))

            autoSwitchConnection = RunService.Heartbeat:Connect(function()
                if not scriptValues.ball or not scriptValues.root then return end

                for _, defender in Players:GetPlayers() do
                    if defender ~= p and not functionModule.sameTeam(defender, p) and defender.Character then
                        local defRoot = defender.Character:FindFirstChild("HumanoidRootPart")

                        if defRoot and (defRoot.Position - scriptValues.root.Position).Magnitude <= 8 then
                            local relativePos = scriptValues.root.CFrame:PointToObjectSpace(defRoot.Position)
                            local shouldBeRight = relativePos.X > 0

                            -- switch hand based on which side defender is on
                            if shouldBeRight and scriptValues.hand == "L" then
                                scriptValues.hand = "R"
                                break
                            elseif not shouldBeRight and scriptValues.hand == "R" then
                                scriptValues.hand = "L"
                                break
                            end
                        end
                    end
                end
            end)
        else
            if autoSwitchConnection then
                autoSwitchConnection:Disconnect()
                autoSwitchConnection = nil
            end
        end
    end
})

--// Stamina \\--
local StaminaBox = Tabs.Movement:AddLeftGroupbox("Stamina", "battery")

--//  \\--
StaminaBox:AddToggle("InfiniteStamina", {
    Text = "Infinite Stamina",
    Default = false,
    Callback = function(v)
        if v then
            local PlayerScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
            local BallFunctions = require(PlayerScripts:FindFirstChild("BallFunctions"))
            local BallValues = require(PlayerScripts:FindFirstChild("BallValues"))

            -- replace the drain function with a no-op that just refills
            BallFunctions.useStamina = function(...)
                BallValues.stamina = 100
                BallValues.staminaMove.Size = UDim2.new(1, 0, 0.8, 0)
                BallValues.staminaMove2.Size = BallValues.staminaMove.Size
                return
            end

            staminaConnection = RunService.Heartbeat:Connect(function()
                BallValues.stamina = 100
                BallValues.staminaMove.Size = UDim2.new(1, 0, 0.8, 0)
                BallValues.staminaMove2.Size = BallValues.staminaMove.Size
            end)
        else
            if staminaConnection then
                staminaConnection:Disconnect()
                staminaConnection = nil
            end
        end
    end
})

--// Visuals Tab \\--
local replicatedModules = ReplicatedStorage:WaitForChild("Modules")
local clothingList = require(replicatedModules:WaitForChild("ClothingList"))

--// clothing \\--
local function getColor(colorName: string): Color3
    if clothingList.Colors[colorName] then
        return clothingList.Colors[colorName][2]
    elseif type(colorName) == "string" and #colorName == 6 then
        return Color3.fromHex(colorName)
    end
    return clothingList.Colors["Institutional white"][2]
end

local function multColor3(color: Color3, mult: number): Color3
    return Color3.new(
        math.clamp(color.R * mult, 0, 1),
        math.clamp(color.G * mult, 0, 1),
        math.clamp(color.B * mult, 0, 1)
    )
end

--// apply a color to shirt, pants, and headband if they use the right templates \\--
local function applyColor(char: Model, colorName: string)
    local color = multColor3(getColor(colorName), 1.2)
    local shirt = char:FindFirstChildOfClass("Shirt")
    local pants = char:FindFirstChildOfClass("Pants")
    local headband = char:FindFirstChild("Headband")

    if shirt and (shirt.ShirtTemplate == "rbxassetid://15973302914" or shirt.ShirtTemplate == "rbxassetid://15973417823") then
        shirt.Color3 = color
    end
    if pants then
        pants.Color3 = color
    end
    if headband and headband.Handle.Mesh.TextureId == "rbxassetid://15973764217" then
        headband.Handle.Mesh.VertexColor = Vector3.new(color.R, color.G, color.B)
    end
end

local VisualsBox = Tabs.Visuals:AddLeftGroupbox("Cosmetics", "shirt")
local colorLoopEnabled = false

--// go through a random jersey color every 0.1s \\--
VisualsBox:AddToggle("RainbowJersey", {
    Text = "Rainbow Jersey",
    Default = false,
    Callback = function(v)
        colorLoopEnabled = v
        if v then
            local colorNames = {}
            for name in pairs(clothingList.Colors) do
                table.insert(colorNames, name)
            end
            spawn(function()
                while colorLoopEnabled do
                    local randomColor = colorNames[math.random(1, #colorNames)]
                    if p.Character then
                        applyColor(p.Character, randomColor)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

local colorList = {}
for name in pairs(clothingList.Colors) do
    table.insert(colorList, name)
end

VisualsBox:AddDropdown("ColorPicker", {
    Values = colorList,
    Default = 1,
    Text = "Jersey Color",
    Callback = function(Value)
        if p.Character then
            applyColor(p.Character, Value)
        end
    end
})

VisualsBox:AddInput("HexColor", {
    Default = "FF0000",
    Text = "Custom Hex Color",
    Placeholder = "FF0000",
    Callback = function(Value)
        if p.Character and #Value == 6 then
            applyColor(p.Character, Value)
        end
    end
})

--// Misc Tab \\--
local MiscLeft = Tabs.Misc:AddLeftGroupbox("Ball Utilities", "circle")
local ballMagConnection, lastPickupTime = nil, 0

--// fires pickup remote on any ball within range every 0.1s (bannable) \\--
MiscLeft:AddToggle("BallMag", {
    Text = "Ball Mag",
    Default = false,
    Callback = function(v)
        if v then
            ballMagConnection = RunService.Heartbeat:Connect(function()
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local currentTime = tick()
                    if currentTime - lastPickupTime >= 0.1 then
                        for _, ball in pairs(workspace.Balls:GetChildren()) do
                            if ball.Name == "Ball" and (ball.Position - char.HumanoidRootPart.Position).Magnitude <= 8 then
                                ReplicatedStorage.BallEvent:FireServer(ball, "pickup")
                                lastPickupTime = currentTime
                                break
                            end
                        end
                    end
                end
            end)
        else
            if ballMagConnection then
                ballMagConnection:Disconnect()
                ballMagConnection = nil
            end
        end
    end
})

local MiscRight = Tabs.Misc:AddRightGroupbox("???????", "shield-check")

--// blocks pushed/knock events from the server and resets knock state every frame \\--
MiscRight:AddToggle("AntiKnockback", {
    Text = "Anti Knockback/Pushed",
    Default = false,
    Callback = function(v)
        if v then
            local sv = require(Players.LocalPlayer.PlayerScripts.BallValues)
            local sf = require(Players.LocalPlayer.PlayerScripts.BallFunctions)
            local vm = require(ReplicatedStorage.Modules.Values)

            antiKnockback = true

            oldKnockNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local args = {...}
                if antiKnockback and getnamecallmethod() == "FireClient" and self.Name == "ballEvent" then
                    -- drop the pushed/knock call so it never runs
                    if args[2] == "pushed" or args[2] == "knock" then
                        return
                    end
                end
                return oldKnockNamecall(self, ...)
            end))

            antiKnockConnection = RunService.Heartbeat:Connect(function()
                if antiKnockback and sv.knocked then
                    sv.knocked = false
                    sv.linearVelocity.Enabled = false
                    sv.alignOrientation.Enabled = false
                    sv.humanoid.AutoRotate = true
                    sv.facePart = nil
                    for _, track in pairs(sv.humanoid:GetPlayingAnimationTracks()) do
                        local id = tonumber(track.Animation.AnimationId:match("%d+"))
                        -- dont stop idle/walk anims
                        if id ~= 507767714 and id ~= 6861835527 then
                            track:Stop()
                        end
                    end
                    sf.changeSpeed(vm.sliders.startingSpeed, false)
                end
                if antiKnockback and sv.linearVelocity.Enabled and not sv.shootBounce and not sv.passRec and not sv.holdingBall then
                    sv.linearVelocity.Enabled = false
                    sv.alignOrientation.Enabled = false
                    sv.humanoid.AutoRotate = true
                    if sv.picking == 0 then
                        sf.changeSpeed(vm.sliders.startingSpeed, false)
                    end
                end
            end)
        else
            antiKnockback = false
            if antiKnockConnection then
                antiKnockConnection:Disconnect()
                antiKnockConnection = nil
            end
        end
    end
})

--//  \\--
MiscRight:AddToggle("AntiAnkleBreaker", {
    Text = "Anti-Ankle Breaker",
    Default = false,
    Callback = function(v)
        local bf = require(Players.LocalPlayer.PlayerScripts.BallFunctions)
        bf.ankles = v and newcclosure(function() end) or (bf.originalAnkles or bf.ankles)
    end
})

--// disable the hitbox touched connection that cause the stun \\--
MiscRight:AddButton({
    Text = "Remove Dunk Poster Stun",
    Func = function()
        local hitBox = Players.LocalPlayer.Character:WaitForChild("hit")
        for _, conn in pairs(getconnections(hitBox.Touched)) do
            conn:Disable()
        end
    end
})

--// Badges \\--
local BadgesBox = Tabs.Misc:AddLeftGroupbox("Badges", "award")

--// sets all badge upgrade costs to 0 so you can unlock them for free (requires badge points tho) \\--
BadgesBox:AddButton({
    Text = "Unlock Potential Badges",
    Func = function()
        local m = require(ReplicatedStorage.Modules.Values)
        for b in pairs(m.badgeUpgrades) do
            m.badgeUpgrades[b] = 0
        end
    end
})

--// Teleports \\--
local TeleportsBox = Tabs.Misc:AddRightGroupbox("Teleports", "map-pin")

--// Place ids mapped to their names \\--
local tp = {
    ["18638157143"] = "Beginner",
    ["113454014057557"] = "Intermediate",
    ["117737879114585"] = "Advanced",
    ["18668109315"] = "Private",
    ["15583100726"] = "Lobby",
    ["138786645426705"] = "Afk Zone",
    ["131054006918765"] = "Park",
    ["111682393431323"] = "Rec Center"
}

for id, name in pairs(tp) do
    TeleportsBox:AddButton({
        Text = name,
        Func = function()
            TeleportService:Teleport(tonumber(id), Players.LocalPlayer)
        end
    })
end

--// Info Tab \\--
local InfoBox = Tabs.Info:AddLeftGroupbox("System Info", "info")

InfoBox:AddLabel("Device: " .. (UserInputService.TouchEnabled and "Mobile" or "PC"))
InfoBox:AddLabel("Executor: " .. (identifyexecutor() or "Unknown"))

--// UI Settings \\--
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default = "RightShift", NoUI = true, Text = "Menu keybind"})

MenuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})

Library.ToggleKeybind = Options.MenuKeybind

--// Theme + Save setup \\--
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Pulse")
SaveManager:SetFolder("Pulse/BasketballStars3")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

--// random junk \\--
local messages = {
    "Script is now open-sourced on my GitHub. Happy skidding!"
}

Library:Notify({
    Title = "Loaded",
    Description = messages[math.random(1, #messages)],
    Time = 10
})

Library:OnUnload(function()
    print("LOOEJ unloaded!")
end)
