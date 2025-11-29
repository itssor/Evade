-- Evade.GG // Loader (The "Robert is Yelling" Edition)
-- Strategy:
-- 1. Check Exact Place ID (Fast)
-- 2. Check Game Name via Marketplace (Slower, but reliable)
-- 3. Universal Fallback (Manual Select)

local Players = game:GetService("Players")
local Market = game:GetService("MarketplaceService")
local PlaceId = game.PlaceId

--// 1. SETUP LIBRARY (Obsidian)
local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Evade.GG",
    Center = true,
    AutoShow = true,
    TabPadding = 8
})

--// 2. DATA TABLES
-- ID Table (The "Fast Lane")
local ID_Map = {
    [16732694052] = "Fisch",
    [5731968301]  = "Fisch",
    [286090429]   = "Arsenal",
    [6516141723]  = "Doors",
    [6839171747]  = "Doors",
    [142823291]   = "MM2",
    [335132309]   = "MM2",
    [12411473842] = "Pressure",
    [17462520831] = "FNTD2"
}

-- Name Table (The "Fuzzy Fallback")
-- Keys are partial strings to search for in the title.
local Name_Map = {
    ["Fisch"] = "Fisch",
    ["Arsenal"] = "Arsenal",
    ["DOORS"] = "Doors",
    ["Murder Mystery 2"] = "MM2",
    ["Pressure"] = "Pressure",
    ["Five Nights TD"] = "FNTD2"
}

--// 3. DETECTION LOGIC
local function DetectGame()
    -- STEP A: ID CHECK
    if ID_Map[PlaceId] then
        print("[Evade] ID Match Found: " .. ID_Map[PlaceId])
        return ID_Map[PlaceId]
    end
    
    -- STEP B: NAME CHECK
    -- "The Robert Maneuver" - Slower, but catches dynamic place IDs
    print("[Evade] ID Unknown. Checking Game Name...")
    local success, info = pcall(function()
        return Market:GetProductInfo(PlaceId)
    end)
    
    if success and info and info.Name then
        print("[Evade] Game Name Fetched: " .. info.Name)
        for searchKey, moduleName in pairs(Name_Map) do
            if string.find(info.Name, searchKey) then
                print("[Evade] Name Match Found: " .. moduleName)
                return moduleName
            end
        end
    else
        warn("[Evade] Failed to fetch Game Info.")
    end
    
    return "Universal"
end

--// 4. LOAD MODULE
local function Load()
    local moduleName = DetectGame()
    local url = "https://raw.githubusercontent.com/itssor/Evade/main/modules/games/" .. moduleName .. ".lua"
    
    if moduleName == "Universal" then
        url = "https://raw.githubusercontent.com/itssor/Evade/main/modules/Universal.lua"
    end
    
    local success, result = pcall(game.HttpGet, game, url)
    
    if success then
        local func, err = loadstring(result)
        if func then
            local Module = func()
            if Module and Module.Init then
                -- Pass the UI instances down
                Module.Init(Library, Window, SaveManager, ThemeManager)
            else
                Library:Notify("Error: Module missing Init()", 5)
            end
        else
            warn("[Evade] Script Syntax Error: " .. tostring(err))
        end
    else
        Library:Notify("HTTP Failed: " .. moduleName, 5)
    end
end

--// 5. EXECUTE
Load()
