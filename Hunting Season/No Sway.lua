local RS = game:GetService("ReplicatedStorage")
local CameraController = require(RS.ReservesCommon.Client.Controllers.CameraController) 
local Rifle = require(RS.ReservesCommon.Equipment.Rifle)

for _,t in pairs(getgc(true)) do
    if type(t)=="table" and rawget(t,"Springs") and rawget(t.Springs,"_sway") then
        t.Springs._sway.Shove = function() end
        t.Springs._cameraBobbing.Shove = function() end
        t.Springs._movement.Offset.Shove = function() end
        t.Springs._movement.Angle.Shove = function() end
    end
end

local old
old = hookfunction(Rifle.Aim, function(self, aiming, fromReload)
    local ret = old(self, aiming, fromReload)
    if aiming then
        workspace.CurrentCamera.FieldOfView = 70 / self.Configurations.Sight.Magnification
        CameraController.SensitivityMultiplier = 1 -- Rifle.lua:504 / Viewmodel.lua:341
    end
    return ret
end)
