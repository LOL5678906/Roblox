-- [[ scriptalua | Last updated 08/15/2026 ]] --

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

--// Services \\--
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

local DarkTheme = {
    WindowColor = ColorSequence.new(Color3.fromRGB(16, 16, 20), Color3.fromRGB(22, 22, 28)),
    ShadowColor = Color3.fromRGB(0, 0, 0),
    SurfaceStroke = Color3.fromRGB(38, 38, 48),
    TitlingColor = Color3.fromRGB(240, 240, 245),
    ContentColor = Color3.fromRGB(175, 175, 190),
    ElementTextHoverColor = Color3.fromRGB(255, 255, 255),
    ActionColor = Color3.fromRGB(200, 200, 215),
    TabColor = Color3.fromRGB(240, 240, 250),
    TabBackground = ColorSequence.new(Color3.fromRGB(28, 28, 36), Color3.fromRGB(20, 20, 26)),
    TabStroke = ColorSequence.new(Color3.fromRGB(50, 50, 65), Color3.fromRGB(35, 35, 48)),
    ElementGradient = ColorSequence.new(Color3.fromRGB(24, 24, 30), Color3.fromRGB(18, 18, 24)),
    ElementStroke = Color3.fromRGB(38, 38, 48),
    ElementStrokeHover = Color3.fromRGB(65, 65, 82),
    AccentColor = Color3.fromRGB(90, 130, 255),
    AccentStroke = Color3.fromRGB(110, 150, 255),
    ToggleTrack = Color3.fromRGB(28, 28, 36),
    ToggleKnobOff = Color3.fromRGB(110, 110, 125),
    SliderBackground = Color3.fromRGB(26, 26, 34),
    SliderProgress = ColorSequence.new(Color3.fromRGB(90, 130, 255), Color3.fromRGB(70, 110, 235)),
    SliderHandle = Color3.fromRGB(240, 240, 255),
    SliderStroke = Color3.fromRGB(45, 45, 60),
    DropdownHighlight = Color3.fromRGB(36, 36, 48),
    FieldBackground = Color3.fromRGB(22, 22, 28),
    PlaceholderColor = Color3.fromRGB(110, 110, 130)
}

--// Window \\--
local Window = Rayfield:CreateWindow({
    name = "SL",
    subtitle = "Basketball Stars 3 | Open Source | By scriptalua",
    theme = DarkTheme
})

--// Tabs \\--
local Tabs = {
    Shooting = Window:CreateTab({ name = "Shooting", icon = "target" }),
    Defense = Window:CreateTab({ name = "Defense", icon = "shield" }),
    Movement = Window:CreateTab({ name = "Movement", icon = "zap" }),
    Visuals = Window:CreateTab({ name = "Visuals", icon = "eye" }),
    Misc = Window:CreateTab({ name = "Misc", icon = "menu" }),
    DribbleModifier = Window:CreateTab({ name = "Dribble Modifier", icon = "zap" }),
    Info = Window:CreateTab({ name = "Info", icon = "info" })
}

--// State \\--
local autoTimeMethod = "Legit"
local autoTimeEnabled = false
local autoLayupReclutchEnabled = false
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
Tabs.Shooting:CreateSection({ name = "Auto Time" })

Tabs.Shooting:CreateDropdown({
    name = "Auto Time Method",
    options = {"Legit", "No Bar", "Auto Bar"},
    value = autoTimeMethod,
    callback = function(v)
        autoTimeMethod = typeof(v) == "table" and v[1] or v
        if autoTimeEnabled then
            if autoTimeMethod == "Legit" then
                setupTween()
            elseif autoTimeMethod == "No Bar" then
                setupNamecall()
            else
                setupVisual()
            end
        end
    end
})

Tabs.Shooting:CreateToggle({
    name = "Auto Time",
    value = autoTimeEnabled,
    callback = function(v)
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

Tabs.Shooting:CreateToggle({
    name = "Auto Layup Reclutch",
    value = false,
    callback = function(v)
        autoLayupReclutchEnabled = v
        if v then
            local inputFunc = filtergc("function", {
                Name = "inputFunction",
                Constants = {"shoot", "jump", "reclutch", "holdingBall", "shootBounce"}
            }, true)

            if not inputFunc then return end

            local old
            old = hookfunction(inputFunc, newcclosure(function(...)
                local scriptValues = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BallValues"))
                if autoLayupReclutchEnabled then
                    scriptValues.reclutch = true
                end
                return old(...)
            end))
        end
    end
})

Tabs.Shooting:CreateSection({ name = "Shot Modifiers" })

--// Hides the shot meter \\--
Tabs.Shooting:CreateButton({
    name = "No Shot Meter",
    callback = function()
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
Tabs.Shooting:CreateButton({
    name = "Easier Moving Shots",
    callback = function()
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
Tabs.Shooting:CreateButton({
    name = "High Shot Arc",
    callback = function()
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

Tabs.Shooting:CreateButton({
    name = "Always Jumpshot State (NEW)",
    callback = function()
        local shootBallFunc = filtergc("function", {
            Constants = {"Jumpshot", "dunk", "Layup", "LayupBackside", "Floater", "Heave"} -- others u can do
        }, true)

        if not shootBallFunc then return end

        local old
        old = hookfunction(shootBallFunc, newcclosure(function(...)
            local args = {...}
            args[1] = "shoot"
            return old(table.unpack(args))
        end))
    end
})

--// Dunk Settings \\--
Tabs.Shooting:CreateSection({ name = "Dunk Settings" })

Tabs.Shooting:CreateToggle({
    name = "Dunk Changer",
    value = dunkChangerEnabled,
    callback = function(v)
        dunkChangerEnabled = v
    end
})

Tabs.Shooting:CreateDropdown({
    name = "Dunk Animation",
    options = {"2 Hand", "Tomahawk", "1 Hand", "Windmill", "Between", "Behind", "180", "Under", "360"},
    value = dunkAnimation,
    callback = function(v)
        dunkAnimation = typeof(v) == "table" and v[1] or v
    end
})

--// patch dunk range \\--
Tabs.Shooting:CreateToggle({
    name = "Unlimited Dunk Range",
    value = false,
    callback = function(v)
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
Tabs.Defense:CreateSection({ name = "Auto Steal" })

Tabs.Defense:CreateToggle({
    name = "Auto Steal",
    value = autoStealEnabled,
    callback = function(v)
        autoStealEnabled = v
        if not v and autoStealIndicator then
            autoStealIndicator:Destroy()
            autoStealIndicator = nil
        end
    end
})

Tabs.Defense:CreateToggle({
    name = "Team Check",
    value = teamCheck,
    callback = function(v)
        teamCheck = v
    end
})

Tabs.Defense:CreateToggle({
    name = "Show Indicator",
    value = showIndicator,
    callback = function(v)
        showIndicator = v
        if not v and autoStealIndicator then
            autoStealIndicator:Destroy()
            autoStealIndicator = nil
        end
    end
})

Tabs.Defense:CreateToggle({
    name = "Steal Animation",
    value = stealAnimation,
    callback = function(v)
        stealAnimation = v
    end
})

Tabs.Defense:CreateSlider({
    name = "Steal Range",
    range = {0.5, 10},
    increment = 0.5,
    value = stealRange,
    callback = function(v)
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
Tabs.Defense:CreateSection({ name = "Auto Contest" })

Tabs.Defense:CreateToggle({
    name = "Auto Contest",
    value = false,
    callback = function(Value)
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
                -- pc version, presses G key when other plr shooting anim detected
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
Tabs.Defense:CreateSection({ name = "Block Settings" })

--// Auto block - presses space when plr shooting anim plays near you \\--
Tabs.Defense:CreateToggle({
    name = "Auto Block",
    value = false,
    callback = function(v)
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

--// Defensive Utilities \\--
Tabs.Defense:CreateSection({ name = "Defensive Utilities" })

Tabs.Defense:CreateButton({
    name = "No Steal Cooldown",
    callback = function()
        local vals = require(Players.LocalPlayer.PlayerScripts.BallValues)
        task.spawn(function()
            while task.wait() do
                if vals.currentAnim == "Steal" then
                    vals.defensiveCooldown = false
                end
            end
        end)
    end
})

--// Movement Tab \\--
Tabs.Movement:CreateSection({ name = "Speed" })

local currtween = nil

--// tween based walkspeed (cant change directly with ws) \\--
Tabs.Movement:CreateToggle({
    name = "Walkspeed",
    value = walkspeedEnabled,
    callback = function(v)
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

Tabs.Movement:CreateSlider({
    name = "Walkspeed Value",
    range = {1, 20},
    increment = 0.25,
    value = walkspeedValue,
    callback = function(v)
        walkspeedValue = v
    end
})

--// Handles Settings \\--
Tabs.Movement:CreateSection({ name = "Handles & Dribble Speed" })

local handlesSpeedValue = 16.25

Tabs.Movement:CreateToggle({
    name = "Handles Speed Changer",
    value = false,
    callback = function(v)
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.handlesSpeed = v and handlesSpeedValue or 16.25
    end
})

Tabs.Movement:CreateSlider({
    name = "Handles Speed",
    range = {10, 25},
    increment = 0.25,
    value = 16.25,
    callback = function(v)
        handlesSpeedValue = v
        require(ReplicatedStorage.Modules.Values).baseSliders.handlesSpeed = v
    end
})

local layupSpeedValue = 12.5

Tabs.Movement:CreateToggle({
    name = "Layup Glide Changer",
    value = false,
    callback = function(v)
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.layupSpeed = v and layupSpeedValue or 12.5
        a.sliders.layupSpeed = v and layupSpeedValue or 12.5
    end
})

Tabs.Movement:CreateSlider({
    name = "Layup Glide Speed",
    range = {1, 25},
    increment = 0.5,
    value = 12.5,
    callback = function(v)
        layupSpeedValue = v
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.layupSpeed = v
        a.sliders.layupSpeed = v
    end
})

--// Switches dribble hand away from the defender automatically \\--
Tabs.Movement:CreateToggle({
    name = "Auto Switch Hands",
    value = false,
    callback = function(v)
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
Tabs.Movement:CreateSection({ name = "Stamina" })

--//  \\--
Tabs.Movement:CreateToggle({
    name = "Infinite Stamina",
    value = false,
    callback = function(v)
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

Tabs.Movement:CreateButton({
    name = "Max Stamina Regen (More legit)",
    callback = function()
        local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
        local scriptValues = require(playerScripts:WaitForChild("BallValues"))

        local mainFunc = filtergc("function", {
            Constants = {"regenLevel"},
            IgnoreExecutor = true
        }, true)

        if mainFunc then
            local upvalues = debug.getupvalues(mainFunc)
            for i, v in pairs(upvalues) do
                if type(v) == "number" and v == 0 then
                    debug.setupvalue(mainFunc, i, 100)
                    break
                end
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

Tabs.Visuals:CreateSection({ name = "Cosmetics" })

local colorLoopEnabled = false

--// go through a random jersey color every 0.1s \\--
Tabs.Visuals:CreateToggle({
    name = "Rainbow Jersey",
    value = false,
    callback = function(v)
        colorLoopEnabled = v
        if v then
            local colorNames = {}
            for name in pairs(clothingList.Colors) do
                table.insert(colorNames, name)
            end
            task.spawn(function()
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

Tabs.Visuals:CreateDropdown({
    name = "Jersey Color",
    options = colorList,
    value = colorList[1] or "Institutional white",
    callback = function(Value)
        local val = typeof(Value) == "table" and Value[1] or Value
        if p.Character and val then
            applyColor(p.Character, val)
        end
    end
})

Tabs.Visuals:CreateInput({
    name = "Custom Hex Color",
    value = "FF0000",
    placeholder = "FF0000",
    callback = function(Value)
        if p.Character and #Value == 6 then
            applyColor(p.Character, Value)
        end
    end
})

--// Misc Tab \\--
Tabs.Misc:CreateSection({ name = "Ball Utilities" })

local ballMagConnection, lastPickupTime = nil, 0

--// fires pickup remote on any ball within range every 0.1s (bannable) \\--
Tabs.Misc:CreateToggle({
    name = "Ball Mag",
    value = false,
    callback = function(v)
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

Tabs.Misc:CreateSection({ name = "Anti-Effects & Stuns" })

--// blocks pushed/knock events from the server and resets knock state every frame \\--
Tabs.Misc:CreateToggle({
    name = "Anti Knockback/Pushed",
    value = false,
    callback = function(v)
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
Tabs.Misc:CreateToggle({
    name = "Anti-Ankle Breaker",
    value = false,
    callback = function(v)
        local bf = require(Players.LocalPlayer.PlayerScripts.BallFunctions)
        bf.ankles = v and newcclosure(function() end) or (bf.originalAnkles or bf.ankles)
    end
})

--// disable the hitbox touched connection that cause the stun \\--
Tabs.Misc:CreateButton({
    name = "Remove Dunk Poster Stun",
    callback = function()
        local hitBox = Players.LocalPlayer.Character:WaitForChild("hit")
        for _, conn in pairs(getconnections(hitBox.Touched)) do
            conn:Disable()
        end
    end
})

Tabs.Misc:CreateSection({ name = "Combat Exploits" })

-- new stuff
Tabs.Misc:CreateButton({
    name = "Stamina Drain (push on touch)",
    callback = function()
        local rep = cloneref(game:GetService("ReplicatedStorage"))
        local plr = Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hit = char:WaitForChild("hit")
        local ev = rep:WaitForChild("BallEvent")

        local old
        old = hookfunction(ev.FireServer, function(self, ...)
            local a = {...}

            if a[2] == "push" and a[3] then
                local t = a[3]

                if t and t ~= plr then
                    for i = 1, 5 do
                        task.spawn(function()
                            old(self, nil, "push", t)
                        end)
                    end
                end
            end

            return old(self, ...)
        end)

        hit.Touched:Connect(function(touchPart)
            if touchPart.Parent and touchPart.Parent:FindFirstChild("Humanoid") then
                local t = Players:GetPlayerFromCharacter(touchPart.Parent)

                if t and t ~= plr and t.Team ~= plr.Team then
                    for i = 1, 3 do
                        task.wait(0.1)
                        ev:FireServer(nil, "push", t)
                    end
                end
            end
        end)
    end
})

--// Badges \\--
Tabs.Misc:CreateSection({ name = "Badges" })

--// sets all badge upgrade costs to 0 so you can unlock them for free (requires badge points tho) \\--
Tabs.Misc:CreateButton({
    name = "Infinite Badge Levels",
    callback = function()
        local rep = cloneref(game:GetService("ReplicatedStorage"))
        local replicatedModulesLocal = rep:WaitForChild("Modules")
        local functionsModule = require(replicatedModulesLocal:WaitForChild("Functions"))

        local oldGetBadgeMaxLevel = functionsModule.getBadgeMaxLevel
        functionsModule.getBadgeMaxLevel = function(badgeName, height, weight)
            return 8
        end

        functionsModule.getBadgeLevel = function(points, badgeName, height, weight)
            return 8, 8
        end

        local valuesModule = require(replicatedModulesLocal:WaitForChild("Values"))
        if valuesModule.badgeUpgrades then
            for badgeName, cost in pairs(valuesModule.badgeUpgrades) do
                valuesModule.badgeUpgrades[badgeName] = 0
            end
        end
    end
})

--// Teleports \\--
Tabs.Misc:CreateSection({ name = "Teleports" })

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
    Tabs.Misc:CreateButton({
        name = name,
        callback = function()
            TeleportService:Teleport(tonumber(id), Players.LocalPlayer)
        end
    })
end

--// Dribble Modifier Tab \\--
Tabs.DribbleModifier:CreateSection({ name = "Moves (Max allowed : 1)" })

local moves = {
    "Cross", "Hezi", "BehindDouble", "Crossover",
    "CrossoverBehind", "Spin", "BTBPickup",
    "StepbackSwitch", "Stepback", "StepbackBetween", "Switch"
}

local selectedMove = "BTBPickup"
local moveChance = 100
local dribbleModifierEnabled = false

Tabs.DribbleModifier:CreateDropdown({
    name = "Dribble Move",
    options = moves,
    value = "BTBPickup",
    callback = function(v)
        selectedMove = typeof(v) == "table" and v[1] or v
    end
})

Tabs.DribbleModifier:CreateSlider({
    name = "Chance of doing that move %",
    range = {1, 100},
    increment = 1,
    value = 100,
    callback = function(v)
        moveChance = v
    end
})

Tabs.DribbleModifier:CreateToggle({
    name = "Enable Dribble Modifier",
    value = false,
    callback = function(v)
        dribbleModifierEnabled = v
    end
})

local executeFunc = filtergc("function", {
    Name = "execute",
    Constants = {"Handle", "Spin", "CrossoverBehind", "Stepback", "BTBPickup"}
}, true)

if executeFunc then
    local old
    old = hookfunction(executeFunc, newcclosure(function(...)
        local args = {...}
        if args[1] == "shoot" or args[1] == "pass" or args[1] == "drop" or args[1] == "steal" or args[1] == "jump" or args[1] == "ability" then
            return old(table.unpack(args))
        end

        if dribbleModifierEnabled and math.random(1, 100) <= moveChance then
            args[1] = "Handle"
            args[2] = selectedMove
        end

        return old(table.unpack(args))
    end))
end

Tabs.DribbleModifier:CreateSection({ name = "Dribble Utilities" })

Tabs.DribbleModifier:CreateButton({
    name = "Unlock All Dribble Moves (centers)",
    callback = function()
        local valuesModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Values"))

        local function safeWrite(tbl, key, value)
            local success = pcall(function()
                tbl[key] = value
            end)
            if not success then
                makewritable(tbl)
                tbl[key] = value
            end
        end

        for _, move in {
            "c", "z", "cc", "zz", "cx", "zx",
            "cxc", "zxz", "cxz", "zxc",
            "xz", "xc", "x", "xx", "v"
        } do
            safeWrite(valuesModule.crossovers, move, move)
        end

        local getVFunc = filtergc("function", {
            Name = "getV"
        }, true)

        if getVFunc then
            hookfunction(getVFunc, newcclosure(function(...)
                return 9999
            end))
        end
    end
})

--// Info Tab \\--
Tabs.Info:CreateSection({ name = "System Info" })

Tabs.Info:CreateButton({
    name = "Device: " .. (UserInputService.TouchEnabled and "Mobile" or "PC"),
    callback = function() end
})

Tabs.Info:CreateButton({
    name = "Executor: " .. (identifyexecutor() or "Unknown"),
    callback = function() end
})

--// random junk \\--
local messages = {
    "2 new features have been added!"
}

Window:Notify({
    title = "Loaded",
    content = messages[math.random(1, #messages)]
})
