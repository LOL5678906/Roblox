-- // @ scriptalua

local RS = game:GetService("ReplicatedStorage")
local CameraController = require(RS.ReservesCommon.Client.Controllers.CameraController) -- CameraController.lua:140
local Spring = require(RS.Classes.Spring) 

local oldAdd
oldAdd = hookfunction(CameraController.AddRotation, function(self, yaw, pitch)
    return -- no change???
end)

local oldShove
oldShove = hookfunction(Spring.Shove, function(self, vec)
    -- (Viewmodel.lua:39), others are 5,50,4,4
    if self.Mass == 3 and self.Force == 80 then
        return
    end
    return oldShove(self, vec)
end)

for _, tbl in pairs(getgc(true)) do
    if type(tbl)=="table" and rawget(tbl, "VerticalRecoil") then
        tbl.VerticalRecoil = 0
    end
end
