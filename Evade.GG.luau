-- Evade.GG // Main Loader (STRICT IMAGE BUILD)
-- Only loading what is in the repository.
-- "Keep it simple, stupid."

local Players = game:GetService("Players")
local PlaceId = game.PlaceId

--// 1. INITIALIZE LIBRARY (Obsidian)
local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

--// 2. CREATE WINDOW
local Window = Library:CreateWindow({
    Title = "Evade.GG",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

--// 3. ROUTING TABLE
-- IDs mapped STRICTLY to the files in your image.
local SupportedGames = {
    -- Arsenal
    [286090429]   = "Arsenal",
    
    -- Doors
    [6516141723]  = "Doors",
    [6839171747]  = "Doors", -- The "Game" place, not just lobby
    
    -- Five Nights TD 2 (FNTD2)
    -- Warning: This ID rotates often. Verify this, Robert.
    [17462520831] = "FNTD2", 
    [18666567958] = "FNTD2", -- Potential Beta/Release ID
    
    -- Fisch
    [16732694052] = "Fisch",
    [5731968301]  = "Fisch",
    
    -- Murder Mystery 2 (MM2)
    [142823291]   = "MM2",
    [335132309]   = "MM2",
    
    -- Pressure
    -- That submarine horror game. 
    [12411473842] = "Pressure"
}

--// 4. MODULE LOADER
local function LoadScript()
    local moduleName = SupportedGames[PlaceId]
    local url
    
    if moduleName then
        print("[Evade] Game Detected: " .. moduleName)
        -- Fetches specific game module
        url = "https://raw.githubusercontent.com/itssor/Evade/main/modules/games/" .. moduleName .. ".lua"
    else
        print("[Evade] Unknown Game. Loading Universal.")
        -- Fallback to Universal.lua as per instructions
        url = "https://raw.githubusercontent.com/itssor/Evade/main/modules/Universal.lua"
    end

    -- Fetch
    local success, result = pcall(game.HttpGet, game, url)
    
    if success then
        local func, err = loadstring(result)
        if func then
            -- Execute
            local Module = func()
            
            -- Init with Obsidian Params
            if Module and Module.Init then
                Module.Init(Library, Window, SaveManager, ThemeManager)
            else
                warn("[Evade] Error: Module missing Init()")
            end
        else
            warn("[Evade] Syntax Error: " .. tostring(err))
        end
    else
        warn("[Evade] Failed to download module: " .. tostring(url))
    end
end

--// 5. EXECUTE
LoadScript()
