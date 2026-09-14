-- // Loader \\ 

local GAS_URL = "https://script.google.com/macros/s/AKfycbxTH5S118C2XlqgbL73O9wLXTTFVlqKjw86lg4_71CeZ-6ex8hYSPRAth3Xre2k2Q6R/exec"

local USER_KEY = getgenv().REFLEX_KEY or ""

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

if type(GAS_URL) ~= "string"
    or not GAS_URL:match("^https://script%.google%.com/macros/s/[A-Za-z0-9-_]+/exec$") then
    LocalPlayer:Kick("[REFLEX] Bad auth URL")
    return
end

local function HWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(id) == "string" and #id > 0 then
        return id
    end
    return "UNKNOWN"
end

local function fetch(url)
    local ok1, r1 = pcall(httpget, url)
    if ok1 and type(r1) == "string" and #r1 > 0 then
        return r1
    end
    local ok2, r2 = pcall(function()
        return request({ Url = url, Method = "GET" })
    end)
    if ok2 and type(r2) == "table" and type(r2.Body) == "string" and #r2.Body > 0 then
        return r2.Body
    end
    local ok3, r3 = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok3 and type(r3) == "string" and #r3 > 0 then
        return r3
    end
    return nil
end

local hwid = HWID()
local raw = fetch(GAS_URL .. "?hwid=" .. HttpService:UrlEncode(hwid)
    .. "&key=" .. HttpService:UrlEncode(USER_KEY)
    .. "&user=" .. HttpService:UrlEncode(LocalPlayer.Name)
    .. "&t=" .. tick())

if not raw then
    LocalPlayer:Kick("[REFLEX] Auth server unreachable")
    return
end

local ok, res = pcall(HttpService.JSONDecode, HttpService, raw)
raw = nil
if not ok or type(res) ~= "table" then
    LocalPlayer:Kick("[REFLEX] Bad auth response")
    return
end

if res.ok ~= true or type(res.src) ~= "string" or #res.src == 0 then
    local reason = tostring(res.reason or "Auth failed")
    pcall(setclipboard, hwid)
    LocalPlayer:Kick("[REFLEX] " .. reason)
    return
end

local chunk = loadstring(res.src, "=reflex")
res = nil
if chunk then
    chunk()
end
