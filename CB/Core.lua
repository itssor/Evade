-- [[ EVADE.GG | COUNTER BLOX CLIENT (v30.0) ]]
local Evade = getgenv().Evade
if not Evade then return end

local Library = Evade.Library
local Window = Evade.Window
local Services = Evade.Services
local Sense = Evade.Sense

-- // UI SETUP
local Tabs = {
    Main = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Misc = Window:AddTab("Misc"),
    Settings = Window:AddTab("Settings")
}

-- // 1. COMBAT
local AimbotGroup = Tabs.Main:AddLeftGroupbox("Aimbot")
AimbotGroup:AddToggle("HitboxExpander", { Text = "Hitbox Expander", Default = false })
AimbotGroup:AddSlider("HitboxSize", { Text = "Head Size", Default = 13, Min = 2, Max = 25, Rounding = 1 })
AimbotGroup:AddSlider("HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })

local AutoGroup = Tabs.Main:AddRightGroupbox("Automation")
AutoGroup:AddToggle("TriggerBot", { Text = "TriggerBot", Default = false })
AutoGroup:AddSlider("TriggerDelay", { Text = "Delay (ms)", Default = 0, Min = 0, Max = 200, Rounding = 0 })
AutoGroup:AddToggle("AutoPistol", { Text = "Auto Pistol", Default = false })

local GunGroup = Tabs.Main:AddLeftGroupbox("Gun Mods (Local)")
GunGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false })
GunGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false })
GunGroup:AddToggle("InstaReload", { Text = "Fast Reload (Anim)", Default = false })
GunGroup:AddToggle("InfAmmo", { Text = "Infinite Ammo (Vis)", Default = false })

-- // 2. VISUALS
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Sense ESP")
ESPGroup:AddToggle("EspEnabled", { Text = "Enabled", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.enabled = v; Sense.Load() end)
ESPGroup:AddToggle("EspBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v end)
ESPGroup:AddToggle("EspName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v end)
ESPGroup:AddToggle("EspHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v end)
ESPGroup:AddToggle("EspTracer", { Text = "Snaplines", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v end)

local WorldESP = Tabs.Visuals:AddRightGroupbox("World ESP")
WorldESP:AddToggle("C4Esp", { Text = "C4 / Bomb", Default = true })
WorldESP:AddToggle("DropEsp", { Text = "Dropped Weapons", Default = true })
WorldESP:AddToggle("NadeEsp", { Text = "Grenades", Default = true })
WorldESP:AddToggle("KitEsp", { Text = "Defuse Kits", Default = true })
WorldESP:AddToggle("HostageEsp", { Text = "Hostages", Default = true })

local ViewGroup = Tabs.Visuals:AddLeftGroupbox("Viewmodel")
ViewGroup:AddToggle("WireframeArms", { Text = "Wireframe Arms", Default = false })
ViewGroup:AddToggle("RainbowArms", { Text = "Rainbow Arms", Default = false })
ViewGroup:AddToggle("NoScope", { Text = "Remove Scope", Default = false })
ViewGroup:AddToggle("BulletTracers", { Text = "Bullet Tracers", Default = false })

local EnvGroup = Tabs.Visuals:AddRightGroupbox("Environment")
EnvGroup:AddToggle("NightMode", { Text = "Night Mode", Default = false })
EnvGroup:AddToggle("NoFlash", { Text = "No Flash", Default = false })
EnvGroup:AddToggle("NoSmoke", { Text = "No Smoke", Default = false })
EnvGroup:AddToggle("Ambience", { Text = "Purple Ambience", Default = false })

-- // 3. MISC
local CamGroup = Tabs.Misc:AddLeftGroupbox("Camera")
CamGroup:AddToggle("FOVEnabled", { Text = "Enable FOV", Default = false })
CamGroup:AddSlider("BaseFOV", { Text = "Base FOV", Default = 90, Min = 70, Max = 150 })
CamGroup:AddToggle("ZoomEnabled", { Text = "Zoom Key (Z)", Default = false })
CamGroup:AddSlider("ZoomFOV", { Text = "Zoom Amount", Default = 15, Min = 1, Max = 60 })

local MoveGroup = Tabs.Misc:AddRightGroupbox("Movement")
MoveGroup:AddToggle("Bhop", { Text = "Bunny Hop", Default = false })
MoveGroup:AddToggle("SpeedHack", { Text = "WalkSpeed", Default = false })
MoveGroup:AddSlider("SpeedVal", { Text = "Value", Default = 16, Min = 16, Max = 100 })

local GameGroup = Tabs.Misc:AddLeftGroupbox("Gameplay")
GameGroup:AddToggle("AutoDefuse", { Text = "Auto Defuse (Distance)", Default = false })
GameGroup:AddToggle("FastPlant", { Text = "Fast Plant (Visual)", Default = false })
GameGroup:AddToggle("RearAlert", { Text = "Rear Alert", Default = true })

-- // LOAD CORE
-- Fetches logic from GitHub
local CoreURL = "https://raw.githubusercontent.com/itssor/Evade/main/CB/Core.lua"
task.spawn(function()
    local S, R = pcall(function() return game:HttpGet(CoreURL) end)
    if S then loadstring(R)() else warn("Core Load Failed") end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload(); Sense.Unload(); if Evade.UnloadCore then Evade.UnloadCore() end end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true })
Library.ToggleKeybind = Library.Options.MenuKey
