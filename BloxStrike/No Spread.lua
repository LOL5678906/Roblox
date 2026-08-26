--[[ @author scriptalua(scriptalua) ]]

local RS = game:GetService("ReplicatedStorage")
local Bullet = require(RS.Components.Weapon.Classes.Bullet)

local old
old = hookfunction(Bullet._performRaycast, function(self, spread)
    return old(self, 0)
end)
