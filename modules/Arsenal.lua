local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Arsenal",
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

-- // 1. COMBAT (RAGE)
local SilentGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
SilentGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Tooltip = "Bullets hit head regardless of aim" })
SilentGroup:AddSlider("SilentFOV", { Text = "FOV Radius", Default = 150, Min = 10, Max = 800, Rounding = 0 })
SilentGroup:AddToggle("DrawSilent", { Text = "Draw FOV", Default = true }):AddColorPicker("SilentColor", { Default = Color3.fromRGB(255, 0, 0) })
SilentGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
SilentGroup:AddSlider("HitChance", { Text = "Hit Chance", Default = 100, Min = 1, Max = 100, Rounding = 0 })

local TriggerGroup = Tabs.Combat:AddRightGroupbox("Trigger Bot")
TriggerGroup:AddToggle("TriggerBot", { Text = "Trigger Bot", Default = false })
TriggerGroup:AddSlider("TriggerDelay", { Text = "Delay (ms)", Default = 0, Min = 0, Max = 500, Rounding = 0 })

-- // 2. WEAPON MODS (EXISTING)
local WepMods = Tabs.Game:AddLeftGroupbox("Weapon Mods")
WepMods:AddToggle("Ars_NoRecoil", { Text = "No Recoil", Default = false })
WepMods:AddToggle("Ars_NoSpread", { Text = "No Spread", Default = false })
WepMods:AddToggle("Ars_RapidFire", { Text = "Rapid Fire", Default = false })
WepMods:AddToggle("Ars_InfAmmo", { Text = "Infinite Ammo", Default = false })
WepMods:AddToggle("Ars_Rainbow", { Text = "Rainbow Gun", Default = false })

-- // 3. EXPLOITS (EXISTING + NEW)
local ExploitGroup = Tabs.Game:AddRightGroupbox("Exploits")
ExploitGroup:AddToggle("Ars_Hitbox", { Text = "Hitbox Expander", Default = false })
ExploitGroup:AddSlider("Ars_HitboxSize", { Text = "Size", Default = 13, Min = 2, Max = 25, Rounding = 1 })
ExploitGroup:AddSlider("Ars_HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })
ExploitGroup:AddToggle("KillSay", { Text = "Kill Say", Default = false })
ExploitGroup:AddToggle("AutoTeam", { Text = "Auto Join Team", Default = false })

local VisGroup = Tabs.Visuals:AddLeftGroupbox("Local Visuals")
VisGroup:AddToggle("ThirdPerson", { Text = "Third Person", Default = false }):AddKeyPicker("TPKey", { Default = "V", Mode = "Toggle" })
VisGroup:AddSlider("TPDist", { Text = "Distance", Default = 10, Min = 5, Max = 20 })

-- // 4. LOGIC: SILENT AIM
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false; FOVCircle.Visible=false

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

-- THE HOOK (Real Silent Aim)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Arsenal uses FindPartOnRay logic for hitscan
    if Library.Toggles.SilentAim.Value and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") and not checkcaller() then
        -- Hit Chance Logic
        if math.random(1, 100) <= Library.Options.HitChance.Value then
            local Target = GetSilentTarget()
            if Target then
                -- Redirect Ray to Target Head
                local Origin = args[1].Origin
                local Direction = (Target.Position - Origin).Unit * 1000
                args[1] = Ray.new(Origin, Direction)
                return oldNamecall(self, unpack(args))
            end
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // 5. LOGIC: TRIGGER BOT
task.spawn(function()
    while true do
        if Library.Toggles.TriggerBot.Value then
            local Target = Mouse.Target
            if Target and Target.Parent then
                local Player = Services.Players:GetPlayerFromCharacter(Target.Parent)
                if Player and Player.Team ~= LocalPlayer.Team then
                    task.wait(Library.Options.TriggerDelay.Value / 1000)
                    mouse1click()
                    task.wait(0.1)
                end
            end
        end
        task.wait()
    end
end)

-- // 6. LOGIC: EXISTING FEATURES (Loops)
task.spawn(function()
    while true do
        -- Weapon Mods
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
        
        -- Auto Team
        if Library.Toggles.AutoTeam.Value and LocalPlayer.PlayerGui:FindFirstChild("Menew") then
            -- Finds the team join remote usually located in ReplicatedStorage.Events
            for _, v in pairs(Services.ReplicatedStorage:GetDescendants()) do
                if v.Name == "JoinTeam" and v:IsA("RemoteFunction") then
                    v:InvokeServer("TBC") -- Try to join TBC/Random
                end
            end
        end
        
        task.wait(2)
    end
end)

-- Kill Say Logic
local KillPhrases = {"Evade.GG On Top", "Sit Down", "Owned by Evade", "Get good", "Config Issue?"}
local LastKills = 0
task.spawn(function()
    while true do
        if Library.Toggles.KillSay.Value then
            local Kills = LocalPlayer.Leaderstats.Kills.Value
            if Kills > LastKills then
                Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(KillPhrases[math.random(#KillPhrases)], "All")
                LastKills = Kills
            end
        end
        task.wait(1)
    end
end)

Services.RunService.RenderStepped:Connect(function()
    -- FOV Circle
    if Library.Toggles.DrawSilent.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true
        FOVCircle.Radius = Library.Options.SilentFOV.Value
        FOVCircle.Color = Library.Options.SilentColor.Value
        FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else
        FOVCircle.Visible = false
    end

    -- Hitbox Expander
    if Library.Toggles.Ars_Hitbox.Value then
        local Size = Library.Options.Ars_HitboxSize.Value
        local Trans = Library.Options.Ars_HitboxTrans.Value
        for _, v in pairs(Services.Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Team ~= LocalPlayer.Team and v.Character then
                pcall(function()
                    for _, P in pairs({"HeadHB", "HumanoidRootPart", "RightUpperLeg", "LeftUpperLeg"}) do
                        local Part = v.Character:FindFirstChild(P)
                        if Part then 
                            Part.CanCollide = false
                            Part.Transparency = Trans
                            Part.Size = Vector3.new(Size, Size, Size) 
                        end
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
        LocalPlayer.CameraMaxZoomDistance = 0 -- Force First Person (Standard Arsenal)
    end
    
    -- Ammo & Rainbow
    if Library.Toggles.Ars_InfAmmo.Value then
        pcall(function() LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 999 end)
    end
    if Library.Toggles.Ars_Rainbow.Value and Camera:FindFirstChild("Arms") then
         for _,v in pairs(Camera.Arms:GetDescendants()) do if v:IsA("MeshPart") then v.Color = Color3.fromHSV(tick()%5/5, 1, 1) end end
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
Evade.SaveManager:SetFolder("Evade/Arsenal")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Arsenal (Silent) Loaded", 5)
