-- // PRE-FLIGHT
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

-- // IMPORTS
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Arsenal (Chimera)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("Arsenal"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- // FEATURES
local SilentGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
SilentGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
SilentGroup:AddSlider("SilentFOV", { Text = "FOV Radius", Default = 150, Min = 10, Max = 800 })
SilentGroup:AddToggle("DrawSilent", { Text = "Draw FOV", Default = true }):AddColorPicker("SilentColor", { Default = Color3.fromRGB(255, 0, 0) })
SilentGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
SilentGroup:AddSlider("HitChance", { Text = "Hit Chance", Default = 100, Min = 1, Max = 100 })

local TriggerGroup = Tabs.Combat:AddRightGroupbox("Trigger Bot")
TriggerGroup:AddToggle("TriggerBot", { Text = "Trigger Bot", Default = false })
TriggerGroup:AddSlider("TriggerDelay", { Text = "Delay (ms)", Default = 0, Min = 0, Max = 500 })

local WepMods = Tabs.Game:AddLeftGroupbox("Weapon Mods")
WepMods:AddToggle("Ars_NoRecoil", { Text = "No Recoil", Default = false })
WepMods:AddToggle("Ars_NoSpread", { Text = "No Spread", Default = false })
WepMods:AddToggle("Ars_RapidFire", { Text = "Rapid Fire", Default = false })
WepMods:AddToggle("Ars_InfAmmo", { Text = "Infinite Ammo", Default = false })
WepMods:AddToggle("Ars_Rainbow", { Text = "Rainbow Gun", Default = false })

local ExploitGroup = Tabs.Game:AddRightGroupbox("Exploits")
ExploitGroup:AddToggle("Ars_Hitbox", { Text = "Hitbox Expander", Default = false })
ExploitGroup:AddSlider("Ars_HitboxSize", { Text = "Size", Default = 13, Min = 2, Max = 25 })
ExploitGroup:AddSlider("Ars_HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1 })
ExploitGroup:AddToggle("KillSay", { Text = "Kill Say", Default = false })
ExploitGroup:AddToggle("AutoTeam", { Text = "Auto Join Team", Default = false })

local VisGroup = Tabs.Visuals:AddRightGroupbox("Local")
VisGroup:AddToggle("ThirdPerson", { Text = "Third Person", Default = false }):AddKeyPicker("TPKey", { Default = "V", Mode = "Toggle" })
VisGroup:AddSlider("TPDist", { Text = "Distance", Default = 10, Min = 5, Max = 20 })

-- [Standard Visuals/Movement Imports Omitted for Brevity - They are identical to Universal]
-- (Assume ESP, Flight, Speed, Noclip groups are added here as per v3.0)
-- ...

-- // LOGIC: SILENT AIM (The "Chimera" Hook)
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Direction = (TargetPart.Position - Origin).Unit * (TargetPart.Position - Origin).Magnitude
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = Services.Workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end

local function GetSilentTarget()
    local T = nil; local D = Library.Options.SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local Head = p.Character:FindFirstChild("Head")
            if Head then
                if not Library.Toggles.WallCheck.Value or IsVisible(Head) then
                    local Pos, Vis = Camera:WorldToViewportPoint(Head.Position)
                    if Vis then
                        local Dist = (MP - Vector2.new(Pos.X, Pos.Y)).Magnitude
                        if Dist < D then D = Dist; T = Head end
                    end
                end
            end
        end
    end
    return T
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.SilentAim.Value and not checkcaller() then
        if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "Raycast" then
            if math.random(1, 100) <= Library.Options.HitChance.Value then
                local Target = GetSilentTarget()
                if Target then
                    -- Universal Argument Replacer
                    if method == "Raycast" then
                        -- Args: Origin, Direction, Params
                        local Origin = args[1]
                        local Direction = (Target.Position - Origin).Unit * 1000
                        args[2] = Direction
                    else
                        -- Args: Ray, IgnoreDescendants
                        local Origin = args[1].Origin
                        local Direction = (Target.Position - Origin).Unit * 1000
                        args[1] = Ray.new(Origin, Direction)
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // LOGIC: KILL SAY (Event Based)
local KillPhrases = {"Evade.GG On Top", "Sit Down", "Owned", "Config Issue?", "Get good"}

local function SetupKillSay()
    if LocalPlayer:FindFirstChild("Leaderstats") and LocalPlayer.Leaderstats:FindFirstChild("Kills") then
        LocalPlayer.Leaderstats.Kills.Changed:Connect(function(NewVal)
            if Library.Toggles.KillSay.Value then
                local Msg = KillPhrases[math.random(#KillPhrases)]
                Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(Msg, "All")
            end
        end)
    end
end
SetupKillSay()
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); SetupKillSay() end)

-- // LOGIC: WEAPON MODS (Loop)
task.spawn(function()
    while true do
        if Library.Toggles.Ars_NoRecoil.Value or Library.Toggles.Ars_NoSpread.Value or Library.Toggles.Ars_RapidFire.Value then
            if Services.ReplicatedStorage:FindFirstChild("Weapons") then
                for _, v in pairs(Services.ReplicatedStorage.Weapons:GetDescendants()) do
                    if Library.Toggles.Ars_NoRecoil.Value and v.Name == "RecoilControl" then v.Value = 0 end
                    if Library.Toggles.Ars_NoSpread.Value and v.Name == "MaxSpread" then v.Value = 0 end
                    if Library.Toggles.Ars_RapidFire.Value and v.Name == "Auto" then v.Value = true end
                    if Library.Toggles.Ars_RapidFire.Value and v.Name == "FireRate" then v.Value = 0.02 end
                end
            end
        end
        
        if Library.Toggles.AutoTeam.Value and LocalPlayer.PlayerGui:FindFirstChild("Menew") then
            -- Attempt to find team remote dynamically
            for _, v in pairs(Services.ReplicatedStorage:GetDescendants()) do
                if v.Name == "JoinTeam" and v:IsA("RemoteFunction") then
                    v:InvokeServer("TBC")
                end
            end
        end
        task.wait(2)
    end
end)

-- // RENDER & PHYSICS (Standard)
Services.RunService.RenderStepped:Connect(function()
    -- FOV
    if Library.Toggles.DrawSilent.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true
        FOVCircle.Radius = Library.Options.SilentFOV.Value
        FOVCircle.Color = Library.Options.SilentColor.Value
        FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end

    -- Hitbox
    if Library.Toggles.Ars_Hitbox.Value then
        local S = Library.Options.Ars_HitboxSize.Value
        local T = Library.Options.Ars_HitboxTrans.Value
        for _, v in pairs(Services.Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Team ~= LocalPlayer.Team and v.Character then
                pcall(function()
                    for _, P in pairs({"HeadHB", "HumanoidRootPart", "RightUpperLeg", "LeftUpperLeg"}) do
                        local Part = v.Character:FindFirstChild(P)
                        if Part then Part.CanCollide = false; Part.Transparency = T; Part.Size = Vector3.new(S,S,S) end
                    end
                end)
            end
        end
    end
    
    -- Third Person
    if Library.Toggles.ThirdPerson.Value then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Library.Options.TPDist.Value
        LocalPlayer.CameraMinZoomDistance = Library.Options.TPDist.Value
    else
        LocalPlayer.CameraMinZoomDistance = 0
        LocalPlayer.CameraMaxZoomDistance = 0
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() 
    getgenv().EvadeLoaded = false
    Library:Unload() 
    Sense.Unload() 
end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Arsenal")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Arsenal Loaded", 5)
