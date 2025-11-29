--[[
    _______ __   __ _______ ______  _______
    |    ___||  |_|  ||   _   ||   _  \|    ___|
    |    ___||       ||       ||  | \  |    ___|
    |_______| |_____| |___|___||__|  |_______|
    
    [ EVADE.GG ] - Ultimate Script Hub
    Version: 2.1 (Counter Blox Added)
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
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local Window = Library:CreateWindow({
    Title = "Evade | Counter Blox",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
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
-- // COMBAT
local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Rage")
AimbotGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
AimbotGroup:AddSlider("SilentFOV", { Text = "FOV", Default = 150, Min = 10, Max = 800 })
AimbotGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = true }):AddColorPicker("FOVColor", { Default = Color3.fromRGB(255, 0, 0) })
AimbotGroup:AddToggle("SnapLines", { Text = "Snap Lines", Default = false })
AimbotGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
AimbotGroup:AddSlider("HitChance", { Text = "Hit Chance", Default = 100, Min = 0, Max = 100 })

local GunGroup = Tabs.Combat:AddRightGroupbox("Gun Mods")
GunGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false })
GunGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false })

-- // VISUALS
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
ESPGroup:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v)
    Sense.teamSettings.enemy.enabled = v
    Sense.Load()
end)
ESPGroup:AddToggle("ESPBox", { Text = "Boxes", Default = true }):OnChanged(function(v) Sense.teamSettings.enemy.box = v end)
ESPGroup:AddToggle("ESPName", { Text = "Names", Default = true }):OnChanged(function(v) Sense.teamSettings.enemy.name = v end)
ESPGroup:AddToggle("ESPHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v end)
ESPGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v end)

local UtilGroup = Tabs.Visuals:AddRightGroupbox("Utility")
UtilGroup:AddToggle("AntiFlash", { Text = "No Flash/Smoke", Default = true })
UtilGroup:AddToggle("Fullbright", { Text = "Fullbright", Default = false })

-- // MOVEMENT
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("Bhop", { Text = "Bunny Hop", Default = false })
MoveGroup:AddToggle("Speed", { Text = "Speed", Default = false })
MoveGroup:AddSlider("SpeedVal", { Text = "Factor", Default = 20, Min = 16, Max = 50 })
MoveGroup:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })

-- // LOGIC
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false; FOVCircle.Visible=false
local SnapLine = Drawing.new("Line"); SnapLine.Thickness=1; SnapLine.Visible=false; SnapLine.Transparency=1

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Direction = (TargetPart.Position - Origin).Unit * (TargetPart.Position - Origin).Magnitude
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera, workspace.Ray_Ignore}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = Services.Workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end

if not getgenv().Evade.Sense.EspInterface then
    getgenv().Evade.Sense.EspInterface = {
        getCharacter = function(Player) return Player.Character end,
        getHealth = function(Character) 
            local Hum = Character and Character:FindFirstChild("Humanoid")
            return Hum and Hum.Health or 100, Hum and Hum.MaxHealth or 100 
local function GetClosest()
    local C = nil; local D = Library.Options.SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local Head = p.Character:FindFirstChild("Head")
            if Head then
                if not Library.Toggles.WallCheck.Value or IsVisible(Head) then
                    local Pos, Vis = Camera:WorldToViewportPoint(Head.Position)
                    if Vis then
                        local Dist = (MP - Vector2.new(Pos.X, Pos.Y)).Magnitude
                        if Dist < D then D = Dist; C = Head end
                    end
                end
            end
        end
    }
    end
    return C
end

-- // 5. GAME DETECTION LOGIC
local PlaceID = game.PlaceId
local Module  = "Universal" 

-- ID Database
local Games = {
    Arsenal       = {286090429, 286090429},
    FNTD2         = {80550384527033, 14816132646},
    MM2           = {142823291, 335132309},
    Pressure      = {12552538295},
    Doors         = {6839171747, 6516141723},
    AR2           = {863266079, 2376885433},
    CounterBlox   = {301549746} -- Added Counter Blox
}
Services.RunService.RenderStepped:Connect(function()
    local MP = Services.UserInputService:GetMouseLocation()
    local Col = Library.Options.FOVColor.Value

    if Library.Toggles.DrawFOV.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.SilentFOV.Value; FOVCircle.Color = Col; FOVCircle.Position = MP
    else FOVCircle.Visible = false end

    if Library.Toggles.SnapLines.Value and Library.Toggles.SilentAim.Value then
        local T = GetClosest()
        if T then
            local P, V = Camera:WorldToViewportPoint(T.Position)
            if V then
                SnapLine.Visible = true; SnapLine.Color = Col; SnapLine.From = MP; SnapLine.To = Vector2.new(P.X, P.Y)
            else SnapLine.Visible = false end
        else SnapLine.Visible = false end
    else SnapLine.Visible = false end
end)

for Name, IDs in pairs(Games) do
    for _, ID in pairs(IDs) do
        if PlaceID == ID then
            Module = Name
            break
-- FIXED HOOK LOGIC
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.SilentAim.Value and method == "FireServer" and self.Name == "HitPart" then
        if math.random(1, 100) <= Library.Options.HitChance.Value then
            local Target = GetClosest()
            if Target then
                args[1] = Target
                args[2] = Target.Position
                -- Safe call to original
                if oldNamecall then
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
end

-- Fallback: Name Check
if Module == "Universal" then
    print("[Evade] ID Check returned Universal. Scanning Name...")
    local Success, Info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(PlaceID)
    end)

    if Success and Info and Info.Name then
        local Name = string.lower(Info.Name)
        print("[Evade] Detected Name: " .. Name)
        
        if string.find(Name, "arsenal") then Module = "Arsenal"
        elseif string.find(Name, "five nights td") or string.find(Name, "fntd") then Module = "FNTD2"
        elseif string.find(Name, "murder mystery") or string.find(Name, "mm2") then Module = "MM2"
        elseif string.find(Name, "pressure") then Module = "Pressure"
        elseif string.find(Name, "doors") then Module = "Doors"
        elseif string.find(Name, "apoc") or string.find(Name, "ar2") then Module = "AR2"
        elseif string.find(Name, "counter blox") or string.find(Name, "cbro") then Module = "CounterBlox"
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- GUN MODS & UTILITY
task.spawn(function()
    while true do
        -- Anti Flash/Smoke
        if Library.Toggles.AntiFlash.Value then
            if LocalPlayer.PlayerGui:FindFirstChild("Blinder") then LocalPlayer.PlayerGui.Blinder.Enabled = false end
            for _, v in pairs(workspace:GetChildren()) do if v.Name == "Smoke" then v:Destroy() end end
        end
    else
        warn("[Evade] Failed to fetch Game Name.")
        task.wait(0.5)
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
-- MOVEMENT LOOP
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    local UnivURL = Config.RepoURL .. Config.Folder .. "Universal.lua"
    local UnivSuccess, UnivErr = pcall(function()
        loadstring(game:HttpGet(UnivURL))()
    end)
    if Library.Toggles.Bhop.Value and Hum and Hum.FloorMaterial == Enum.Material.Air then Hum.Jump = true end
    if Library.Toggles.Speed.Value and Hum then Hum.WalkSpeed = Library.Options.SpeedVal.Value end

    if not UnivSuccess then
        getgenv().EvadeLoaded = false
        Notify("Evade Error", "Universal Fallback Failed. Script Terminated.", 10)
        warn("[Evade] Fatal Error: " .. tostring(UnivErr))
    if Library.Toggles.Fullbright.Value then
        Services.Lighting.Brightness = 2; Services.Lighting.ClockTime = 14; Services.Lighting.FogEnd = 100000
    end
end
print("----------------------------------------")
end)

Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().EvadeLoaded = false; Library:Unload(); Sense.Unload() end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/CounterBlox")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Counter Blox Loaded", 5)
