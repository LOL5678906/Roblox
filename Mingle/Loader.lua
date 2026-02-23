local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)()
local Wait = library.subs.Wait
local PepsisWorld = library:CreateWindow({Name = "Mingle | Credit : Norgumi", Themeable = {Info = ""}})
local GeneralTab = PepsisWorld:CreateTab({Name = "General"})
local Secondary = GeneralTab:CreateSection({Name = "Main"})
local Combat = GeneralTab:CreateSection({Name = "Push Settings"})

local pushX = 0
local pushY = 0
local pushZ = 0

Combat:AddSlider(
    {
        Name = "Push Left/Right",
        Min = 0,
        Max = 1000,
        Default = 0,
        Callback = function(value)
            pushX = value
        end
    }
)

Combat:AddSlider(
    {
        Name = "Push Up/Down",
        Min = 0,
        Max = 1000,
        Default = 15,
        Callback = function(value)
            pushY = value
        end
    }
)

Combat:AddSlider(
    {
        Name = "Push Forward/Back",
        Min = 0,
        Max = 1000,
        Default = 0,
        Callback = function(value)
            pushZ = value
        end
    }
)

Combat:AddButton(
    {
        Name = "Push Extender [X]",
        Callback = function()
            local remote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("PushPlayer")
            local plr = game.Players.LocalPlayer
            local box = Instance.new("SelectionBox")
            box.LineThickness = 0.01
            box.Color3 = Color3.fromRGB(255, 255, 255)
            box.SurfaceTransparency = 0.8
            box.Transparency = 0.8
            local function getRootPart()
                if plr.Character then
                    return plr.Character:FindFirstChild("HumanoidRootPart")
                end
                return nil
            end
            plr.CharacterAdded:Connect(
                function(char)
                    char:WaitForChild("HumanoidRootPart")
                end
            )
            game:GetService("UserInputService").InputBegan:Connect(
                function(input)
                    if input.KeyCode == Enum.KeyCode.X then
                        local root = getRootPart()
                        if not root then
                            return
                        end
                        local nearest = nil
                        local mindist = math.huge
                        for _, v in pairs(game.Players:GetPlayers()) do
                            if v ~= plr and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = (v.Character.HumanoidRootPart.Position - root.Position).Magnitude
                                if dist < mindist then
                                    mindist = dist
                                    nearest = v
                                end
                            end
                        end
                        if nearest then
                            box.Adornee = nearest.Character
                            box.Parent = nearest.Character
                            local args = {[1] = nearest, [2] = Vector3.new(pushX, pushY, pushZ)}
                            remote:InvokeServer(unpack(args))
                            task.wait(1)
                            box.Parent = nil
                        end
                    end
                end
            )
        end
    }
)

Secondary:AddToggle(
    {
        Name = "Door Glitch [Y]",
        Callback = function()
            local plr = game.Players.LocalPlayer
            local ts = game:GetService("TweenService")
            local uis = game:GetService("UserInputService")
            local function setup(char)
                local root = char:WaitForChild("HumanoidRootPart")
                local function getNearestDoor()
                    local nearest
                    local mindist = math.huge
                    for _, v in workspace:GetDescendants() do
                        if v:IsA("UnionOperation") and v.Name == "Door" then
                            local dist = (root.Position - v.Position).Magnitude
                            if dist < mindist then
                                mindist = dist
                                nearest = v
                            end
                        end
                    end
                    return nearest, mindist
                end
                uis.InputBegan:Connect(
                    function(key)
                        if key.KeyCode == Enum.KeyCode.Y then
                            local door, dist = getNearestDoor()
                            if door and dist <= 6 then
                                local tween = ts:Create(root, TweenInfo.new(0.3), {CFrame = door.CFrame})
                                tween:Play()
                            end
                        end
                    end
                )
            end
            setup(plr.Character or plr.CharacterAdded:Wait())
            plr.CharacterAdded:Connect(setup)
        end
    }
)

Secondary:AddButton(
    {
        Name = "Enable Reset",
        Callback = function()
            game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
            game.Players.LocalPlayer.DevEnableMouseLock = true
        end
    }
)

Secondary:AddButton(
    {
        Name = "Loop Rainbow Clothing",
        Callback = function()
            local mod = require(game:GetService("ReplicatedStorage"):WaitForChild("JumpsuitModule"))
            local getdata = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GetData", true)
            local RunService = game:GetService("RunService")
            local items = {}
            for cat, catItems in pairs(mod) do
                for _, item in pairs(catItems) do
                    table.insert(items, item)
                end
            end
            local index = 1
            RunService.Heartbeat:Connect(
                function()
                    getdata:InvokeServer("equip", items[index])
                    index = index >= #items and 1 or index + 1
                end
            )
        end
    }
)

Secondary:AddButton(
    {
        Name = "Join VC server",
        Callback = function()
            local ts = game:GetService("TeleportService")
            local vcid = 133875023675852
            hookfunction(
                game:GetService("VoiceChatService").IsVoiceEnabledForUserIdAsync,
                function()
                    return true
                end
            )
            ts:Teleport(vcid, game.Players.LocalPlayer)
        end
    }
)
