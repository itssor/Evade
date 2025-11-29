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
GunGroup:AddToggle("RapidFire", { Text = "Rapid Fire", Default = false })

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
    end
    return C
end

Services.RunService.RenderStepped:Connect(function()
    local MP = Services.UserInputService:GetMouseLocation()
    local Col = Library.Options.FOVColor.Value

    if Library.Toggles.DrawFOV.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.SilentFOV.Value; FOVCircle.Color = Col; FOVCircle.Position = MP
    else FOVCircle.Visible = false end

    if Library.Toggles.SnapLines.Value and Library.Toggles.SilentAim.Value then
        local Target = GetClosest()
        if Target then
            local Pos, Vis = Camera:WorldToViewportPoint(Target.Position)
            if Vis then
                SnapLine.Visible = true; SnapLine.Color = Col; SnapLine.From = MP; SnapLine.To = Vector2.new(Pos.X, Pos.Y)
            else SnapLine.Visible = false end
        else SnapLine.Visible = false end
    else SnapLine.Visible = false end
end)

-- // THE HYBRID HOOK
local oldNamecall
local success = pcall(function()
    -- Attempt standard hookmetamethod
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Library.Toggles.SilentAim.Value and not checkcaller() and method == "FireServer" and self.Name == "HitPart" then
            if math.random(1, 100) <= Library.Options.HitChance.Value then
                local Target = GetClosest()
                if Target then
                    args[1] = Target
                    args[2] = Target.Position
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- Fallback if hookmetamethod failed or returned nil
if not success or not oldNamecall then
    warn("[Evade] hookmetamethod failed or nil, switching to getrawmetatable")
    local mt = getrawmetatable(game)
    oldNamecall = mt.__namecall
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Library.Toggles.SilentAim.Value and not checkcaller() and method == "FireServer" and self.Name == "HitPart" then
            if math.random(1, 100) <= Library.Options.HitChance.Value then
                local Target = GetClosest()
                if Target then
                    args[1] = Target
                    args[2] = Target.Position
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

-- LOOPS
task.spawn(function()
    while true do
        if Library.Toggles.AntiFlash.Value then
            if LocalPlayer.PlayerGui:FindFirstChild("Blinder") then LocalPlayer.PlayerGui.Blinder.Enabled = false end
            for _, v in pairs(workspace:GetChildren()) do if v.Name == "Smoke" then v:Destroy() end end
        end
        task.wait(0.5)
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Library.Toggles.Bhop.Value and Hum and Hum.FloorMaterial == Enum.Material.Air then Hum.Jump = true end
    if Library.Toggles.Speed.Value and Hum then Hum.WalkSpeed = Library.Options.SpeedVal.Value end
    if Library.Toggles.Fullbright.Value then
        Services.Lighting.Brightness = 2; Services.Lighting.ClockTime = 14; Services.Lighting.FogEnd = 100000
    end
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

Library:Notify("Evade | Counter Blox (Hybrid) Loaded", 5)
