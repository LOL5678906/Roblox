local RS = game:GetService("ReplicatedStorage")
local LS = game:GetService("LogService")


local Service = nil
for _, v in getgc(true) do
    if type(v) == "table" and rawget(v, "GETACINFO") then
        Service = v
        break
    end
end

if Service and Service.GETACINFO then
    Service.GETACINFO.OnClientInvoke = function()
        return true
    end
end

for _, v in getgc() do
    if type(v) == "function" and islclosure(v) then
        local consts = debug.getconstants(v)
        
        if table.find(consts, "PSTAND") or table.find(consts, "NOCLIP") or table.find(consts, "Luraph Script:") or table.find(consts, "BAVEL") then
            for i, c in consts do
                if c == "PSTAND" or c == "BGYR" or c == "BVEL" or c == "NOCLIP" or c == "HBIN" or c == "ANIM" or c == "BAVEL" or c == "Luraph Script:" then
                    debug.setconstant(v, i, "")
                end
            end
        end
        
        if table.find(consts, "goodbye cringelord") or table.find(consts, "got you!!! teehee!!") then
            local upvals = debug.getupvalues(v)
            for i, u in upvals do
                if u == true then
                    debug.setupvalue(v, i, false)
                end
            end
        end
        
        if table.find(consts, 100000) then
            hookfunction(v, function() end)
        end
    end
end


warn(1)
