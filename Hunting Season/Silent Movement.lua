local RS = game:GetService("ReplicatedStorage")
local rem = RS:WaitForChild("Remotes"):WaitForChild("PlayerNoiseEvent") -- Gameplay.lua:829

local old
old = hookfunction(rem.FireServer, function(self, lvl)
    if self ~= rem then return old(self, lvl) end
    return old(self, 0)
end)

for _,t in pairs(getgc(true)) do
    if type(t)=="table" and rawget(t,"NoiseRange") and rawget(t,"VerticalRecoil") then
        t.NoiseRange = 0 -- Rifle.lua:170-172 (note)
    end
end
