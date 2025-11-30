--[[
    EVADE.GG - MASTER LOADER
    Version: 3.0 (Modular + Detection)
    Repository: https://github.com/itssor/Evade
    Author: Pine (Cell Block D)
]]

-- // 0. SINGLETON CHECK
if getgenv().EvadeLoaded then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Evade.GG",
        Text = "Script is already running!",
        Duration = 5
    })
    return
end
getgenv().EvadeLoaded = true

-- // 1. CONFIGURATION
local Repo = "https://raw.githubusercontent.com/itssor/Evade/main/Modules/"

-- // 2. SERVICES
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    MarketplaceService = game:GetService("MarketplaceService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- // 3. LOAD CORE LIBRARIES
-- UI Library (Obsidian)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

-- ESP Library (Sense)
local Sense = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Sirius/request/library/sense/source.lua"))()

-- Patch Sense Interface (Prevent Nil Errors)
if not Sense.EspInterface then
    Sense.EspInterface = {
        getCharacter = function(Player) return Player.Character end,
        getHealth = function(Character) 
            local Hum = Character and Character:FindFirstChild("Humanoid")
            return Hum and Hum.Health or 100, Hum and Hum.MaxHealth or 100 
        end
    }
end

-- // 4. GAME DATABASE
-- [PlaceID] = "ModuleName.lua"
local Games = {
    -- Arsenal
    [286090429] = "Arsenal.lua",
    
    -- Five Nights TD
    [80550384527033] = "FNTD.lua",
    [14816132646] = "FNTD.lua",
    
    -- Phantom Forces
    [292439477] = "PhantomForces.lua",
    [299659045] = "PhantomForces.lua",
    
    -- Murder Mystery 2
    [142823291] = "MM2.lua",
    [335132309] = "MM2.lua",
    
    -- Counter Blox
    [301549746] = "CounterBlox.lua",
    [3272915504] = "CounterBlox.lua", -- Remastered
    
    -- Trident Survival
    [13335293290] = "Trident.lua"
}

-- // 5. DETECTION LOGIC
local PlaceID = game.PlaceId
local ModuleName = "Universal.lua" -- Default
local DetectedName = "Universal"

-- Check ID First (Fastest)
if Games[PlaceID] then
    ModuleName = Games[PlaceID]
    DetectedName = ModuleName:gsub(".lua", "")
else
    -- Check Name Fallback (Slower but covers multiple place IDs)
    local Success, Info = pcall(function()
        return Services.MarketplaceService:GetProductInfo(PlaceID)
    end)
    
    if Success and Info and Info.Name then
        local Name = string.lower(Info.Name)
        if string.find(Name, "arsenal") then 
            ModuleName = "Arsenal.lua"; DetectedName = "Arsenal"
        elseif string.find(Name, "five nights td") or string.find(Name, "fntd") then 
            ModuleName = "FNTD.lua"; DetectedName = "FNTD"
        elseif string.find(Name, "phantom forces") then 
            ModuleName = "PhantomForces.lua"; DetectedName = "Phantom Forces"
        elseif string.find(Name, "murder mystery 2") or string.find(Name, "mm2") then 
            ModuleName = "MM2.lua"; DetectedName = "MM2"
        elseif string.find(Name, "counter blox") then 
            ModuleName = "CounterBlox.lua"; DetectedName = "Counter Blox"
        elseif string.find(Name, "trident survival") then
            ModuleName = "Trident.lua"; DetectedName = "Trident"
        end
    end
end

-- // 6. UI CONSTRUCTION
Library.Font = Enum.Font.Ubuntu

local Window = Library:CreateWindow({
    Title = "Evade.GG | " .. DetectedName,
    Center = true, 
    AutoShow = true, 
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- // 7. GLOBAL API SETUP
-- This allows modules to access the window and libraries
getgenv().Evade = {
    Library = Library,
    Window = Window,
    Services = Services,
    Sense = Sense,
    LocalPlayer = LocalPlayer,
    Camera = Camera,
    GameMode = DetectedName
}

-- // 8. LOAD MODULE
-- This fetches the specific game script (e.g., Modules/Arsenal.lua)
task.spawn(function()
    local Url = Repo .. ModuleName
    local Success, Err = pcall(function()
        loadstring(game:HttpGet(Url))()
    end)
    
    if not Success then
        warn("Evade.GG Error: Failed to load module " .. ModuleName)
        warn(Err)
        -- Fallback to Universal if specific module fails
        loadstring(game:HttpGet(Repo .. "Universal.lua"))()
    end
end)

-- // 9. INIT MANAGERS
-- These act as placeholders until the Module populates the tabs
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("Evade")
SaveManager:SetFolder("Evade/" .. DetectedName)

-- Notify User
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Evade.GG",
    Text = "Loaded: " .. DetectedName,
    Duration = 5
})
