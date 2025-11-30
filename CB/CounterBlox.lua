-- [[ COUNTER BLOX: CLIENT (THIN) ]]
local Evade = getgenv().Evade or {}
getgenv().Evade = Evade -- Ensure Global

-- // 1. SETUP UI
local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(Repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(Repo .. 'addons/SaveManager.lua'))()
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Sirius/request/library/sense/source.lua'))()

local Window = Library:CreateWindow({ Title = "Counter Blox | Cloud", Center = true, AutoShow = true, TabPadding = 8 })
local Tabs = { Combat = Window:AddTab("Combat"), Visuals = Window:AddTab("Visuals"), Intel = Window:AddTab("Intel"), Misc = Window:AddTab("Misc"), Settings = Window:AddTab("Settings") }

-- // 2. POPULATE API
Evade.Library = Library
Evade.Window = Window
Evade.Tabs = Tabs
Evade.Sense = Sense
Evade.Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService")
}
Evade.LocalPlayer = game:GetService("Players").LocalPlayer
Evade.Camera = workspace.CurrentCamera

-- // 3. CREATE TOGGLES (So the Core has something to read)
local Combat = Tabs.Combat:AddLeftGroupbox("Hitbox")
Combat:AddToggle("HitboxExpander", { Text = "Hitbox Expander", Default = false })
Combat:AddSlider("HitboxSize", { Text = "Size", Default = 13, Min = 2, Max = 25, Rounding = 1 })
Combat:AddSlider("HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })

local GunGroup = Tabs.Combat:AddRightGroupbox("Gun Mods")
GunGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false })
GunGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false })

local PlayerESP = Tabs.Visuals:AddLeftGroupbox("Players")
PlayerESP:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.enabled = v; Sense.Load() end)
PlayerESP:AddToggle("EspBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v end)
PlayerESP:AddToggle("EspName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v end)
PlayerESP:AddToggle("EspHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v end)
PlayerESP:AddToggle("CarrierEsp", { Text = "Bomb Carrier ESP", Default = true })

local WorldESP = Tabs.Visuals:AddRightGroupbox("World")
WorldESP:AddToggle("DropEsp", { Text = "Dropped Guns", Default = true })
WorldESP:AddToggle("C4Esp", { Text = "C4 ESP", Default = true })

local EnvGroup = Tabs.Visuals:AddLeftGroupbox("Environment")
EnvGroup:AddToggle("NoFlash", { Text = "No Flash", Default = false })
EnvGroup:AddToggle("NoSmoke", { Text = "No Smoke", Default = false })

local SpecGroup = Tabs.Intel:AddLeftGroupbox("Intel")
SpecGroup:AddToggle("SpecList", { Text = "Show Spectator List", Default = true })

local MoveGroup = Tabs.Misc:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("Bhop", { Text = "Bunny Hop", Default = false })
MoveGroup:AddToggle("RearAlert", { Text = "Rear Alert", Default = true })
MoveGroup:AddSlider("AlertDist", { Text = "Alert Distance", Default = 20, Min = 5, Max = 50 })

local CamGroup = Tabs.Misc:AddRightGroupbox("Camera")
CamGroup:AddToggle("EnableZoom", { Text = "Zoom (Key: Z)", Default = false })
CamGroup:AddSlider("ZoomFOV", { Text = "Zoom Level", Default = 15, Min = 1, Max = 60 })
CamGroup:AddSlider("BaseFOV", { Text = "Base FOV", Default = 90, Min = 70, Max = 120 })

-- // 4. LOAD THE BRAIN
-- Fetches the logic loop from GitHub
local CoreURL = "https://raw.githubusercontent.com/itssor/Evade/refs/heads/main/CB/Core.lua"
task.spawn(function()
    local S, R = pcall(function() return game:HttpGet(CoreURL) end)
    if S then loadstring(R)() else warn("Failed to load Core Logic!") end
end)

-- // 5. SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() 
    Library:Unload()
    Sense.Unload()
    if Evade.UnloadCore then Evade.UnloadCore() end 
end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true })
Library.ToggleKeybind = Library.Options.MenuKey

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKey"})
SaveManager:SetFolder("CB_Cloud")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
