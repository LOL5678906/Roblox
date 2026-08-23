local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LivingThings = workspace:WaitForChild("LivingThings")

local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerAttack = Remotes:WaitForChild("ZombieRelated"):WaitForChild("PlayerAttack")
local MeleeDamage = Remotes:WaitForChild("Melee"):WaitForChild("Damage")
local GunsDamage = Remotes:WaitForChild("Guns"):WaitForChild("Damage")
local SharedRemote = ReplicatedStorage:WaitForChild("NetworkEvents"):WaitForChild("RemoteEvent")

local Config = {
	Enabled = true,
	Range = 25,
	Delay = 0.25,
	Fists = true,
	Melee = true,
	GunDamage = true,
	GunsDamage = true,
}

local function GetRoot(Model)
	if not Model then
		return nil
	end
	return Model:FindFirstChild("HumanoidRootPart") or Model:FindFirstChildWhichIsA("BasePart")
end

local function CanAttack(Target, Character)
	local TargetTeam = Target:GetAttribute("Team")
	local MyTeam = Character:GetAttribute("Team")
	if TargetTeam ~= MyTeam then
		return true
	end
	return Target:GetAttribute("Hostile") == true or Character:GetAttribute("Hostile") == true
end

local function GetHitPart(Model)
	return Model:FindFirstChild("Head")
		or Model:FindFirstChild("Torso")
		or Model:FindFirstChild("UpperTorso")
		or Model:FindFirstChild("HumanoidRootPart")
		or Model:FindFirstChildWhichIsA("BasePart")
end

local function AttackTarget(Model, HitPart, Character)
	if Config.Fists then
		task.spawn(function()
			pcall(function()
				PlayerAttack:InvokeServer(HitPart)
			end)
		end)
	end
	if Config.Melee then
		task.spawn(function()
			pcall(function()
				MeleeDamage:InvokeServer(HitPart)
			end)
		end)
	end
	if Config.GunDamage then
		task.spawn(function()
			pcall(function()
				SharedRemote:FireServer("GUN_DAMAGE", Model)
			end)
		end)
	end
	if Config.GunsDamage then
		task.spawn(function()
			pcall(function()
				GunsDamage:FireServer(HitPart)
			end)
		end)
	end
end

getgenv().KillAura = {
	Config = Config,
}

task.spawn(function()
	while true do
		if Config.Enabled then
			pcall(function()
				local Character = LocalPlayer.Character
				local MyRoot = GetRoot(Character)
				if not Character or not MyRoot then
					return
				end
				for _, Model in ipairs(LivingThings:GetChildren()) do
					if Model:IsA("Model") and Model ~= Character then
						local Humanoid = Model:FindFirstChildOfClass("Humanoid")
						local RootPart = GetRoot(Model)
						if Humanoid and Humanoid.Health > 0 and RootPart and CanAttack(Model, Character) then
							if (RootPart.Position - MyRoot.Position).Magnitude <= Config.Range then
								local HitPart = GetHitPart(Model)
								if HitPart then
									AttackTarget(Model, HitPart, Character)
								end
							end
						end
					end
				end
			end)
		end
		task.wait(Config.Delay)
	end
end)
