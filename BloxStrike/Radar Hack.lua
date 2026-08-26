--[[ @author scriptalua(scriptalua) ]]

local RS = game:GetService("ReplicatedStorage")

task.spawn(function()
	while task.wait(1) do
		local target = filtergc("function", {Name = "GetEnemyVisibility"}, true)
		if not target then
			local ok, radar = pcall(require, RS.Interface.Screens.Gameplay.Middle.Radar)
			if ok and type(radar) == "table" and type(radar.UpdatePlayerIcons) == "function" then
				for i = 1, 32 do
					local uv = debug.getupvalue(radar.UpdatePlayerIcons, i)
					if type(uv) == "function" and type(debug.getupvalue(uv, 1)) == "function" then
						target = uv
						break
					end
				end
			end
		end
		if target then
			hookfunction(target, function() return true end)
			break
		end
	end
end)
