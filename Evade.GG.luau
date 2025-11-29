--[[
    _______ __   __ _______ ______  _______
    |    ___||  |_|  ||   _   ||   _  \|    ___|
    |    ___||       ||       ||  | \  |    ___|
    |_______| |_____| |___|___||__|  |_______|
    
    [ EVADE.GG ] - Ultimate Script Hub
    Version: 2.1 (Robust Name Scanner)
    Author: Itssor
    License: Open Source
]]

-- // 0. INITIALIZATION CHECK
if getgenv().EvadeLoaded then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Evade.GG",
        Text = "Script is already active!",
        Duration = 5
    })
    return
end
getgenv().EvadeLoaded = true

-- // 1. CONFIGURATION
local Config = {
    RepoURL = "https://raw.githubusercontent.com/itssor/Evade/main/",
    Folder  = "modules/", 
    
    Libraries = {
        Obsidian = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/",
        Sense    = "https://raw.githubusercontent.com/jensonhirst/Sirius/request/library/sense/source.lua"
    }
}

-- // 2. GLOBAL ENVIRONMENT SETUP
getgenv().Evade = {
    Services = {
        Players           = game:GetService("Players"),
        RunService        = game:GetService("RunService"),
        Workspace         = game:GetService("Workspace"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        UserInputService  = game:GetService("UserInputService"),
        VirtualUser       = game:GetService("VirtualUser"),
        Lighting          = game:GetService("Lighting"),
        HttpService       = game:GetService("HttpService"),
        TeleportService   = game:GetService("TeleportService"),
        CollectionService = game:GetService("CollectionService"),
        MarketplaceService= game:GetService("MarketplaceService")
    },
    LocalPlayer = game:GetService("Players").LocalPlayer,
    Camera      = game:GetService("Workspace").CurrentCamera,
    Mouse       = game:GetService("Players").LocalPlayer:GetMouse()
}

-- // 3. UTILITY FUNCTIONS
local function SafeLoad(Url, DebugName)
    local Success, Result = pcall(function() return game:HttpGet(Url) end)
    if not Success then 
        warn("[Evade] Failed to download: " .. DebugName)
        return nil 
    end
    
    local Func, SyntaxErr = loadstring(Result)
    if not Func then 
        warn("[Evade] Syntax Error in " .. DebugName .. ": " .. tostring(SyntaxErr))
        return nil 
    end
    
    local RunSuccess, RunResult = pcall(Func)
    if not RunSuccess then 
        warn("[Evade] Runtime Error in " .. DebugName .. ": " .. tostring(RunResult))
        return nil 
    end
    
    return RunResult
end

local function Notify(Title, Text, Duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Duration or 5
    })
end

-- // 4. LIBRARY INJECTION
Notify("Evade.GG", "Initializing Core...", 3)

local Libs = Config.Libraries
getgenv().Evade.Library      = SafeLoad(Libs.Obsidian .. 'Library.lua', "Obsidian UI")
getgenv().Evade.ThemeManager = SafeLoad(Libs.Obsidian .. 'addons/ThemeManager.lua', "Theme Manager")
getgenv().Evade.SaveManager  = SafeLoad(Libs.Obsidian .. 'addons/SaveManager.lua', "Save Manager")
getgenv().Evade.Sense        = SafeLoad(Libs.Sense, "Sense ESP")

if not getgenv().Evade.Library or not getgenv().Evade.Sense then
    getgenv().EvadeLoaded = false
    Notify("Evade Critical", "Failed to load libraries. Check Console (F9).", 10)
    return
end

if not getgenv().Evade.Sense.EspInterface then
    getgenv().Evade.Sense.EspInterface = {
        getCharacter = function(Player) return Player.Character end,
        getHealth = function(Character) 
            local Hum = Character and Character:FindFirstChild("Humanoid")
            return Hum and Hum.Health or 100, Hum and Hum.MaxHealth or 100 
        end
    }
end

-- // 5. GAME DETECTION LOGIC
local PlaceID = game.PlaceId
local Module  = "Universal" 

-- Priority: Exact ID Match
local Games = {
    Arsenal       = {286090429, 286090429},
    FNTD2         = {80550384527033, 14816132646},
    MM2           = {142823291, 335132309},
    Pressure      = {12552538295},
    Doors         = {6839171747, 6516141723},
    AR2           = {863266079, 2376885433}
}

for Name, IDs in pairs(Games) do
    for _, ID in pairs(IDs) do
        if PlaceID == ID then
            Module = Name
            break
        end
    end
end

-- Fallback: Smart Name Detection
if Module == "Universal" then
    print("[Evade] ID Check returned Universal. Scanning Name...")
    local Success, Info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(PlaceID)
    end)
    
    if Success and Info and Info.Name then
        local Name = string.lower(Info.Name)
        print("[Evade] Detected Name: " .. Name)
        
        -- Fuzzy Matching
        if string.find(Name, "arsenal") then Module = "Arsenal"
        elseif string.find(Name, "five nights td") or string.find(Name, "fntd") then Module = "FNTD2"
        elseif string.find(Name, "murder mystery") or string.find(Name, "mm2") then Module = "MM2"
        elseif string.find(Name, "pressure") then Module = "Pressure"
        elseif string.find(Name, "doors") then Module = "Doors"
        elseif string.find(Name, "apoc") or string.find(Name, "ar2") or string.find(Name, "rising") then Module = "AR2"
        end
    else
        warn("[Evade] Failed to fetch Game Name.")
    end
end

-- // 6. MODULE EXECUTION
Notify("Evade.GG", "Game Detected: " .. Module, 5)
print("----------------------------------------")
print("[Evade] Target Module: " .. Module)

local ModuleURL = Config.RepoURL .. Config.Folder .. Module .. ".lua"
local Success, Err = pcall(function()
    loadstring(game:HttpGet(ModuleURL))()
end)

if not Success then
    warn("[Evade] Failed to load " .. Module .. " Module!")
    warn("[Evade] Error: " .. tostring(Err))
    
    Notify("Evade Warning", "Module failed. Loading Universal fallback...", 5)
    
    local UnivURL = Config.RepoURL .. Config.Folder .. "Universal.lua"
    local UnivSuccess, UnivErr = pcall(function()
        loadstring(game:HttpGet(UnivURL))()
    end)
    
    if not UnivSuccess then
        getgenv().EvadeLoaded = false
        Notify("Evade Error", "Universal Fallback Failed. Script Terminated.", 10)
        warn("[Evade] Fatal Error: " .. tostring(UnivErr))
    end
end
print("----------------------------------------")
