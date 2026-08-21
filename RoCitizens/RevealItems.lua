-- // @scriptalua (for night market)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Relays = ReplicatedStorage.Modules.Events.NightMarket.Relays
local FunctionLibrary = require(ReplicatedStorage.FunctionLibrary)

local function RevealAllItems()
    local ok, data = pcall(FunctionLibrary.GetDataFile)
    local stock = ok and data and data.NightMarketData and data.NightMarketData.Stock

    local count = (stock and #stock) or 5
    for i = 1, count do
        Relays.StockUnhidden:FireServer(i)
    end

    return true
end

RevealAllItems()
