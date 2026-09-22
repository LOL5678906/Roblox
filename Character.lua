--// Services
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local GroupService = game:GetService("GroupService")

local FrontAPI = {}

--// Configuration
FrontAPI.TeamCheck = true
FrontAPI.LogNames = true
FrontAPI.CacheTime = 5
FrontAPI.TickRate = 0.1

--// Vars
FrontAPI.LocalPlayer = Players.LocalPlayer
FrontAPI.RP = RaycastParams.new()
FrontAPI.RP.FilterType = Enum.RaycastFilterType.Blacklist
FrontAPI.RP.IgnoreWater = true

local CacheList, CacheTime = {}, 0
local CharCache = {}
local IsBB, IsPF = false, false
local BBChars, BBTeams, BBMap = nil, nil, {}
local PFList, PFChan = {}, nil
local PFTick = 0

pcall(function()
    if game.CreatorType == Enum.CreatorType.Group then
        local Info = GroupService:GetGroupInfoAsync(game.CreatorId)
        if Info then
            IsBB = Info.Name == "Bad Business"
            IsPF = Info.Name == "StyLiS Studios"
        end
    end
end)
FrontAPI.IsBB = IsBB
FrontAPI.IsPF = IsPF
warn(IsBB and "Using custom Bad Business module." or IsPF and "Using custom Phantom Forces module." or "Using default character loader.")

--// Custom loaders
--// ----------------------------------------------------------------
--// Bad Business
function FrontAPI.BBRefresh()
    if BBChars and BBTeams then
        local Ok, Fn = pcall(function() return rawget(BBChars, "GetCharacter") end)
        if Ok and typeof(Fn) == "function" then
            local Store = debug.getupvalues(Fn)[1]
            if typeof(Store) == "table" then
                BBMap = {}
                for k, v in pairs(Store) do BBMap[tostring(typeof(v) == "Instance" and v.Name or v)] = tostring(k) end
                FrontAPI.BBMap = BBMap
                return
            end
        end
    end
    BBMap = {}
    for _, t in ipairs(getgc(true)) do
        if typeof(t) == "table" and rawget(t, "Characters") and rawget(t, "Teams") then
            local Ch, Tm = rawget(t, "Characters"), rawget(t, "Teams")
            if BBChars == nil and typeof(rawget(Ch, "GetCharacter")) == "function" then BBChars = Ch end
            if BBTeams == nil and typeof(rawget(Tm, "GetPlayerTeam")) == "function" then BBTeams = Tm end
        end
    end
    if BBChars then
        local Fn = rawget(BBChars, "GetCharacter")
        if typeof(Fn) == "function" then
            local Store = debug.getupvalues(Fn)[1]
            if typeof(Store) == "table" then
                for k, v in pairs(Store) do BBMap[tostring(typeof(v) == "Instance" and v.Name or v)] = tostring(k) end
            end
        end
    end
    FrontAPI.BBMap = BBMap
end
--// ----------------------------------------------------------------
--// Phantom Forces
function FrontAPI.PFRefresh()
    if PFChan == nil then
        local Id, Ch = create_comm_channel()
        PFChan = { Id = Id, Ch = Ch }
        Ch.Event:Connect(function(Data) PFList = Data FrontAPI.PFList = Data end)
    end
    run_on_thread(getactorthreads()[1], [==[
        local Id = ...
        local Ch = get_comm_channel(Id)
        local RI = getrenv().shared.require("ReplicationInterface")
        local Out = {}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            local Entry = RI.getEntry(p)
            local TPO = Entry and Entry:getThirdPersonObject()
            local Chr = TPO and TPO:getCharacterHash()
            if Chr then
                local Parts = {}
                for _, Part in pairs(Chr) do
                    if typeof(Part) == "Instance" and Part:IsA("BasePart") then Parts[#Parts + 1] = Part end
                end
                if #Parts > 0 then Out[p.Name] = { Parts = Parts, Team = tostring(p.TeamColor) } end
            end
        end
        Ch:Fire(Out)
    ]==], PFChan.Id)
end
--// ----------------------------------------------------------------

function FrontAPI.RealName(Model)
    if IsBB then
        local Hit = BBMap[Model.Name]
        if Hit then return Hit end
        if BBChars then
            local Ok, Owner = pcall(function() return BBChars.GetPlayerFromCharacter(Model) end)
            if Ok and Owner ~= nil then return typeof(Owner) == "Instance" and Owner.Name or tostring(Owner) end
        end
    end
    local Plr = nil
    pcall(function() Plr = Players:GetPlayerFromCharacter(Model) end)
    if Plr then return Plr.Name end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == Model then return p.Name end
    end
    return Model.Name
end

function FrontAPI.TeamOf(Real)
    local p = Players:FindFirstChild(Real)
    if not p then return "?" end
    if IsBB and BBTeams then
        local Ok, Team = pcall(function() return BBTeams:GetPlayerTeam(p) end)
        if Ok and Team then return tostring(Team) end
        return "?"
    end
    local Team = nil
    pcall(function() Team = p.Team end)
    if Team then return Team.Name end
    return tostring(p.TeamColor)
end

function FrontAPI.IsChar(Model)
    if typeof(Model) ~= "Instance" or not Model:IsA("Model") then return false end
    if not Model:IsDescendantOf(Workspace) then return false end
    local Cam = Workspace.CurrentCamera
    if Cam and Model:IsDescendantOf(Cam) then return false end
    if rawequal(Model, FrontAPI.LocalPlayer.Character) then return false end
    if FrontAPI.LocalPlayer.Character and Model:IsDescendantOf(FrontAPI.LocalPlayer.Character) then return false end
    local cached = CharCache[Model]
    local hasPart, hasHealth
    if cached then
        hasPart, hasHealth = cached[1], cached[2]
    else
        hasPart = Model:FindFirstChildWhichIsA("BasePart", true) ~= nil
        hasHealth = Model:FindFirstChild("Health") ~= nil
        CharCache[Model] = { hasPart, hasHealth }
    end
    if not hasPart then return false end
    local Real = FrontAPI.RealName(Model)
    if Real == FrontAPI.LocalPlayer.Name then return false end
    if FrontAPI.TeamCheck then
        local A, B = FrontAPI.TeamOf(Real), FrontAPI.TeamOf(FrontAPI.LocalPlayer.Name)
        if A ~= "?" and B ~= "?" and A == B and A ~= "FFA" then return false end
    end
    if not hasHealth then
        local Hum = Model:FindFirstChildOfClass("Humanoid")
        if not (Hum and Hum.Health > 0) then return false end
    end
    return true
end

function FrontAPI.Vis(Org, Pos, Model, Parts)
    local Dir = Pos - Org
    if Dir.Magnitude < 0.5 then return false end
    local Hit = Workspace:Raycast(Org, Dir, FrontAPI.RP)
    if Hit == nil then return true end
    local HitPart = Hit.Instance
    if Parts then
        for _, Part in ipairs(Parts) do
            if Part == HitPart then return true end
        end
    end
    if Model and HitPart and HitPart:IsDescendantOf(Model) then return true end
    return (Hit.Position - Org).Magnitude >= Dir.Magnitude - 5
end

function FrontAPI.View(Cam, Pos)
    local Ok, Sp, On = pcall(function() return Cam:WorldToViewportPoint(Pos) end)
    if not Ok or not On or Sp.Z <= 0 then return false end
    return Sp.X >= 0 and Sp.Y >= 0 and Sp.X <= Cam.ViewportSize.X and Sp.Y <= Cam.ViewportSize.Y
end

function FrontAPI.Cands()
    if os.clock() - CacheTime < FrontAPI.CacheTime and #CacheList > 0 then return CacheList end
    if IsBB then FrontAPI.BBRefresh() end
    local Out = {}
    local Root = Workspace:FindFirstChild("Characters") or Workspace
    for _, m in ipairs(Root:GetChildren()) do
        if typeof(m) == "Instance" and m:IsA("Model") then Out[#Out + 1] = m end
    end
    CacheList, CacheTime = Out, os.clock()
    return Out
end

function FrontAPI.Get()
    local Cam = Workspace.CurrentCamera
    if not Cam then return {} end
    local Filter = { Cam }
    if FrontAPI.LocalPlayer.Character then Filter[#Filter + 1] = FrontAPI.LocalPlayer.Character end
    FrontAPI.RP.FilterDescendantsInstances = Filter
    local Org = Cam.CFrame.Position
    if IsPF then
        if os.clock() - PFTick > 0.5 then PFTick = os.clock() FrontAPI.PFRefresh() end
        local Found, Seen = {}, {}
        for Name, Data in pairs(PFList) do
            if Name ~= FrontAPI.LocalPlayer.Name and tostring(Data.Team) ~= tostring(FrontAPI.LocalPlayer.TeamColor) then
                local n = 0
                for _, Part in ipairs(Data.Parts) do
                    n += 1
                    if n > 4 then break end
                    if FrontAPI.View(Cam, Part.Position) and FrontAPI.Vis(Org, Part.Position, nil, Data.Parts) then
                        if not Seen[Name] then Seen[Name] = true Found[#Found + 1] = Name end
                        break
                    end
                end
            end
        end
        if #Found > 0 and FrontAPI.LogNames then warn(table.concat(Found, ", ")) end
        return Found
    end
    local Found, Seen = {}, {}
    for _, m in ipairs(FrontAPI.Cands()) do
        if FrontAPI.IsChar(m) then
            local n = 0
            for _, p in ipairs(m:GetDescendants()) do
                if p:IsA("BasePart") then
                    n += 1
                    if n > 4 then break end
                    if FrontAPI.View(Cam, p.Position) and FrontAPI.Vis(Org, p.Position, m) then
                        local Nm = FrontAPI.RealName(m)
                        if not Seen[Nm] then Seen[Nm] = true Found[#Found + 1] = Nm end
                        break
                    end
                end
            end
        end
    end
    if #Found > 0 and FrontAPI.LogNames then warn(table.concat(Found, ", ")) end
    return Found
end

if IsBB then FrontAPI.BBRefresh() end
return FrontAPI
