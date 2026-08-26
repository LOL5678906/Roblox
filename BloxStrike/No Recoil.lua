--[[ @author scriptalua(scriptalua) ]]

local RS = game:GetService("ReplicatedStorage")
local CameraController = require(RS.Controllers.CameraController)

-- Weapon.lua kickCamera() -> weaponKick(), setupRecoil stepped loop -> setWeaponRecoil()
hookfunction(CameraController.weaponKick, function() end)
hookfunction(CameraController.setWeaponRecoil, function() end)
