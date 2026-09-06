local RS = game:GetService("ReplicatedStorage")
local Rifle = require(RS.ReservesCommon.Equipment.Rifle) -- Rifle.lua:830

-- MagazineCapacity <= BulletsInMagazine
local old
old = hookfunction(Rifle.Fire, function(self, ...)
    if rawget(self, "BulletsInMagazine") then
        self.BulletsInMagazine = self.MagazineCapacity or 99
    end
    return old(self, ...)
end)

task.spawn(function()
    while old do
        for _,t in pairs(getgc(true)) do
            if type(t)=="table" and rawget(t,"BulletsInMagazine") and rawget(t,"MagazineCapacity") then
                t.BulletsInMagazine = t.MagazineCapacity
                t.Reloading = false -- Rifle.lua:943
            end
        end
        task.wait(0.1)
    end
end)
