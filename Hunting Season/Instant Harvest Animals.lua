local RS = game:GetService("ReplicatedStorage")
local harvest = RS.ReservesCommon.Remotes.HarvestAnimal -- ReplicationController.lua:439
local preserve = RS.ReservesCommon.Remotes.PreserveHarvest -- Harvest.lua:102 

for _,m in ipairs(workspace.DeadAnimals:GetChildren()) do
    local id = m:GetAttribute("Id")
    if not id then -- fallback ???????
        local pp = m:FindFirstChild("ProximityPromptParent",true)
        if pp and pp.Value then id = pp.Value:GetAttribute("AnimalId") end
    end
    if id then
        harvest:FireServer(id)
        task.wait(0.08)
    end
end

workspace.DeadAnimals.ChildAdded:Connect(function(m)
    task.wait(0.2)
    local id = m:GetAttribute("Id") or (m:FindFirstChild("ProximityPromptParent",true) and m:FindFirstChild("ProximityPromptParent",true).Value:GetAttribute("AnimalId"))
    if id then harvest:FireServer(id) end
end)
