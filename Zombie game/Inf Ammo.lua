local Guns = game:GetService("ReplicatedStorage").Remotes.Guns
task.spawn(function()
    while task.wait(0.05) do
        for _, v in getgc(true) do
            if type(v) == "table" and rawget(v, "Ammo") ~= nil and rawget(v, "Tool") ~= nil then
                v.Ammo = 99
                v.Loaded = true
            end
        end
        pcall(function() Guns.Reload:FireServer() end)
        pcall(function() Guns.ShotgunLoad:FireServer() end)
        local c = game.Players.LocalPlayer.Character
        local t = c and c:FindFirstChildOfClass("Tool")
        if t and t:GetAttribute("Ammo") ~= nil then
            pcall(function() t:SetAttribute("Ammo", 99) end)
        end
    end
  end
