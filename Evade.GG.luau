--[[
    EVADE.GG - MASTER LOADER (v33.0)
    Repo: https://github.com/milkisbetter/Evade
    Status: Bedwars Support Removed (Safety)
]]

-- // 0. SINGLETON CHECK
if getgenv().EvadeLoaded then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Evade.GG", Text = "Already loaded!", Duration = 5})
    return
end
getgenv().EvadeLoaded = true

-- // CONFIGURATION
local RepoURL = "https://raw.githubusercontent.com/milkisbetter/Evade/main/"
local Folder = "modules/" 

-- // 1. GLOBAL ENVIRONMENT
getgenv().Evade = {
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        Workspace = game:GetService("Workspace"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        UserInputService = game:GetService("UserInputService"),
        VirtualUser = game:GetService("VirtualUser"),
        Lighting = game:GetService("Lighting"),
        HttpService = game:GetService("HttpService"),
        TeleportService = game:GetService("TeleportService"),
        CollectionService = game:GetService("CollectionService")
    },
    LocalPlayer = game:GetService("Players").LocalPlayer,
    Camera = game:GetService("Workspace").CurrentCamera,
    Mouse = game:GetService("Players").LocalPlayer:GetMouse()
}

-- // 2. LOAD LIBRARIES (ONCE)
local function SafeLoad(Url, Name)
    local Success, Result = pcall(function() return game:HttpGet(Url) end)
    if not Success then return nil, "Network Error" end
    local Func, SyntaxErr = loadstring(Result)
    if not Func then return nil, "Syntax Error: " .. tostring(SyntaxErr) end
    local RunSuccess, RunResult = pcall(Func)
    if not RunSuccess then return nil, "Runtime Error: " .. tostring(RunResult) end
    return RunResult
end

local LibRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

getgenv().Evade.Library = SafeLoad(LibRepo .. 'Library.lua', "Obsidian Lib")
getgenv().Evade.ThemeManager = SafeLoad(LibRepo .. 'addons/ThemeManager.lua', "ThemeManager")
getgenv().Evade.SaveManager = SafeLoad(LibRepo .. 'addons/SaveManager.lua', "SaveManager")
getgenv().Evade.Sense = SafeLoad('https://raw.githubusercontent.com/jensonhirst/Sirius/request/library/sense/source.lua', "Sense ESP")

-- Pre-Flight Check
if not getgenv().Evade.Library or not getgenv().Evade.Sense then
    getgenv().EvadeLoaded = false
    warn("CRITICAL: Libraries failed to load.")
    return
end

-- Patch Sense
if not getgenv().Evade.Sense.EspInterface then
    getgenv().Evade.Sense.EspInterface = {
        getCharacter = function(Player) return Player.Character end,
        getHealth = function(Character) 
            local Hum = Character and Character:FindFirstChild("Humanoid")
            return Hum and Hum.Health or 100, Hum and Hum.MaxHealth or 100 
        end
    }
end

-- // 3. DETECT GAME
local PlaceID = game.PlaceId
local Module = "Universal" -- Default Fallback

if PlaceID == 286090429 or PlaceID == 286090429 then 
    Module = "Arsenal"
elseif PlaceID == 80550384527033 or PlaceID == 14816132646 then 
    Module = "FNTD2"
elseif PlaceID == 142823291 or PlaceID == 335132309 then 
    Module = "MM2"
end

-- // 4. EXECUTE MODULE
print("[Evade] Loading: " .. Module)

local Success, Err = pcall(function()
    loadstring(game:HttpGet(RepoURL .. Folder .. Module .. ".lua"))()
end)

if not Success then
    warn("[Evade] " .. Module .. " Failed: " .. tostring(Err))
    warn("[Evade] Loading Universal Fallback...")
    
    local UnivSuccess, UnivErr = pcall(function()
        loadstring(game:HttpGet(RepoURL .. Folder .. "Universal.lua"))()
    end)
    
    if not UnivSuccess then
        getgenv().EvadeLoaded = false
        warn("[Evade] Universal Failed: " .. tostring(UnivErr))
    end
end
