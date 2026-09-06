local RS = game:GetService("ReplicatedStorage")
local unlock = RS:WaitForChild("Remotes"):WaitForChild("UnlockLocation") -- LocationManager.lua:48

for _,v in ipairs(workspace.LocationRegions:GetChildren()) do
    if v:IsA("BasePart") then
        unlock:FireServer(v.Name)
        task.wait(0.03)
    end
end

local Hint = require(RS.ReservesCommon.Client.Controllers.HintController)
for _,m in ipairs(workspace.Animals:GetChildren()) do
    Hint.Waypoint.new(m:GetPivot().Position, m.Name, true, 10, true, workspace)
end
