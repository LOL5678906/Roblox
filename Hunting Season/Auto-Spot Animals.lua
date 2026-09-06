local RS = game:GetService("ReplicatedStorage")
local spot = RS:WaitForChild("ReservesCommon"):WaitForChild("Remotes"):WaitForChild("SpotAnimal") -- Binoculars.lua:505
local spotBird = RS.ReservesCommon.Remotes:FindFirstChild("SpotBird")

local function spotAll()
    for _,m in ipairs(workspace.Animals:GetChildren()) do
        local id = m:GetAttribute("Id")
        if id then
            -- 305 radius
            if m:GetAttribute("ClientSide") then
                if spotBird then spotBird:FireServer(id) end
            else
                spot:FireServer(id) 
            end
            task.wait(0.02) 
        end
    end
end

spotAll()

workspace.Animals.ChildAdded:Connect(function(m)
    task.wait(0.5)
    local id = m:GetAttribute("Id")
    if id then spot:FireServer(id) end
end)
