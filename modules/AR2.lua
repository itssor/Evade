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
local Workspace = Services.Workspace

-- // 1. CUSTOM PERSISTENT ESP MANAGER
local ObjectESP = {
    Cache = {},
    Enabled = true
}

function ObjectESP.Add(Obj, Config)
    if not Obj or ObjectESP.Cache[Obj] then return end
    
    local Text = Drawing.new("Text")
    Text.Visible = false
    Text.Center = true
    Text.Outline = true
    Text.Size = 13
    Text.Text = Config.Name or "Unknown"
    Text.Color = Config.Color or Color3.new(1,1,1)

    ObjectESP.Cache[Obj] = { Text = Text, Config = Config, Root = Obj }
end

function ObjectESP.Remove(Obj)
    if ObjectESP.Cache[Obj] then
        ObjectESP.Cache[Obj].Text:Remove()
        ObjectESP.Cache[Obj] = nil
    end
end

function ObjectESP.Clear()
    for Obj, _ in pairs(ObjectESP.Cache) do
        ObjectESP.Remove(Obj)
    end
end

-- Update Loop
Services.RunService.RenderStepped:Connect(function()
    for Obj, Data in pairs(ObjectESP.Cache) do
        if not Obj or not Obj.Parent then
            ObjectESP.Remove(Obj)
            continue
        end

        local IsEnabled = false
        if Data.Config.Type == "Zombie" and Library.Toggles.ZombieESP.Value then IsEnabled = true end
        if Data.Config.Type == "Loot" and Library.Toggles.LootESP.Value then IsEnabled = true end
        if Data.Config.Type == "Vehicle" and Library.Toggles.VehicleESP.Value then IsEnabled = true end

        if IsEnabled and ObjectESP.Enabled then
            local Pos, Vis = Camera:WorldToViewportPoint(Obj.Position)
            if Vis then
                Data.Text.Visible = true
                Data.Text.Position = Vector2.new(Pos.X, Pos.Y)
            else
                Data.Text.Visible = false
            end
        else
            Data.Text.Visible = false
        end
    end
end)

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | AR2 (Stable)",
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
local SilentGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
SilentGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
SilentGroup:AddSlider("SilentFOV", { Text = "FOV", Default = 150, Min = 10, Max = 800 })
SilentGroup:AddToggle("DrawSilent", { Text = "Draw FOV", Default = true }):AddColorPicker("SilentColor", { Default = Color3.fromRGB(255, 0, 0) })
SilentGroup:AddToggle("SnapLines", { Text = "Snap Lines", Default = false, Tooltip = "Draws line to target" })
SilentGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })

local GunGroup = Tabs.Combat:AddRightGroupbox("Gun Mods")
GunGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false })
GunGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false })
GunGroup:AddToggle("NoSway", { Text = "No Sway", Default = false })

-- // VISUALS
local PlayerGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP (Sense)")
PlayerGroup:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v)
    Sense.teamSettings.enemy.enabled = v
    Sense.teamSettings.friendly.enabled = v 
    Sense.Load()
    ObjectESP.Enabled = v
end)
PlayerGroup:AddToggle("ESPBox", { Text = "Boxes", Default = true }):OnChanged(function(v) Sense.teamSettings.enemy.box = v; Sense.teamSettings.friendly.box = v end)
PlayerGroup:AddToggle("ESPName", { Text = "Names", Default = true }):OnChanged(function(v) Sense.teamSettings.enemy.name = v; Sense.teamSettings.friendly.name = v end)
PlayerGroup:AddToggle("ESPHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v; Sense.teamSettings.friendly.healthBar = v end)
PlayerGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v; Sense.teamSettings.friendly.tracer = v end)

local CustomVis = Tabs.Visuals:AddRightGroupbox("World ESP")
CustomVis:AddToggle("ZombieESP", { Text = "Zombie ESP", Default = false })
CustomVis:AddToggle("LootESP", { Text = "Rare Loot ESP", Default = false })
CustomVis:AddToggle("VehicleESP", { Text = "Vehicle ESP", Default = false })

-- // MOVEMENT
local FlightGroup = Tabs.Movement:AddLeftGroupbox("Flight")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300 })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 20, Min = 16, Max = 50 })
SpeedGroup:AddToggle("InfStamina", { Text = "Infinite Stamina", Default = false })
SpeedGroup:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
SpeedGroup:AddToggle("Noclip", { Text = "Noclip", Default = false })

-- // LOGIC: SCANNER
task.spawn(function()
    while true do
        -- ZOMBIES
        local ZFolder = Workspace:FindFirstChild("Zombies") or Workspace:FindFirstChild("Animals")
        if ZFolder then
            for _, z in pairs(ZFolder:GetDescendants()) do
                if z:IsA("Model") and z:FindFirstChild("HumanoidRootPart") and z:FindFirstChild("Humanoid") then
                    if not Services.Players:GetPlayerFromCharacter(z) then
                        ObjectESP.Add(z.HumanoidRootPart, {Name = "Infected", Color = Color3.fromRGB(255, 170, 0), Type = "Zombie"})
                    end
                end
            end
        end

        -- LOOT
        if Library.Toggles.LootESP.Value then
            for _, v in pairs(Workspace:GetDescendants()) do
                if (v.Name == "Military Crate" or v.Name == "Police Crate" or v.Name:find("Gun")) and v:IsA("Model") and v.PrimaryPart then
                    ObjectESP.Add(v.PrimaryPart, {Name = v.Name, Color = Color3.fromRGB(0, 255, 0), Type = "Loot"})
                end
            end
        end

        -- VEHICLES
        local VFolder = Workspace:FindFirstChild("Vehicles")
        if VFolder then
            for _, v in pairs(VFolder:GetChildren()) do
                if v.PrimaryPart then
                    ObjectESP.Add(v.PrimaryPart, {Name = v.Name, Color = Color3.fromRGB(0, 100, 255), Type = "Vehicle"})
                end
            end
        end

        task.wait(1)
    end
end)

-- // LOGIC: SILENT AIM & SNAP LINES
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false; FOVCircle.Visible=false
local SnapLine = Drawing.new("Line"); SnapLine.Thickness=1; SnapLine.Visible=false; SnapLine.Transparency=1

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Direction = (TargetPart.Position - Origin).Unit * (TargetPart.Position - Origin).Magnitude
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = Services.Workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end

local function GetClosest()
    local C = nil; local D = Library.Options.SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    
    -- Scan Players
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local Char = p.Character
            if Char then
                local Head = Char:FindFirstChild("Head")
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
    end
    return C
end

Services.RunService.RenderStepped:Connect(function()
    -- Update Color Variables
    local SilentColor = Library.Options.SilentColor.Value
    local MousePos = Services.UserInputService:GetMouseLocation()

    -- FOV
    if Library.Toggles.DrawSilent.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true
        FOVCircle.Radius = Library.Options.SilentFOV.Value
        FOVCircle.Color = SilentColor
        FOVCircle.Position = MousePos
    else
        FOVCircle.Visible = false
    end

    -- Snap Lines
    if Library.Toggles.SnapLines.Value and Library.Toggles.SilentAim.Value then
        local Target = GetClosest()
        if Target then
            local Pos, Vis = Camera:WorldToViewportPoint(Target.Position)
            if Vis then
                SnapLine.Visible = true
                SnapLine.Color = SilentColor
                SnapLine.From = MousePos
                SnapLine.To = Vector2.new(Pos.X, Pos.Y)
            else
                SnapLine.Visible = false
            end
        else
            SnapLine.Visible = false
        end
    else
        SnapLine.Visible = false
    end
end)

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.SilentAim.Value and method == "FireServer" and (self.Name == "Fire" or self.Name == "Shoot" or self.Name == "Projectiles") then
        local Target = GetClosest()
        if Target then
            for i, v in pairs(args) do
                if typeof(v) == "Vector3" then
                    args[i] = (Target.Position - Camera.CFrame.Position).Unit * 1000
                    break
                elseif typeof(v) == "CFrame" then
                    args[i] = CFrame.new(Camera.CFrame.Position, Target.Position)
                    break
                end
            end
            if oldNamecall then return oldNamecall(self, unpack(args)) end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // MOVEMENT & RECOIL
task.spawn(function()
    while true do
        if Library.Toggles.NoRecoil.Value then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "Recoil") then
                    v.Recoil = 0; v.Spread = 0; v.Kick = 0; v.Sway = 0
                end
            end
        end
        task.wait(2)
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Library.Toggles.InfStamina.Value then
        local Stats = LocalPlayer.Character:FindFirstChild("Stats")
        if Stats and Stats:FindFirstChild("Stamina") then Stats.Stamina.Value = 100 end
    end

    if Library.Toggles.FlightEnabled.Value and Library.Options.FlightKey:GetState() and HRP then
        local Mode = Library.Options.FlightMode.Value
        local Speed = Library.Options.FlightSpeed.Value
        local Dir = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end
        
        local LV = HRP:FindFirstChild("SWFly") or Instance.new("LinearVelocity", HRP); LV.Name = "SWFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        LV.Attachment0 = HRP:FindFirstChild("RootAttachment") or Instance.new("Attachment", HRP)
        LV.VectorVelocity = Dir * Speed
        
        if Mode == "CFrame" then HRP.Anchored = true; HRP.CFrame = HRP.CFrame + (Dir * (Speed/50)) else HRP.Anchored = false end
    else
        if HRP and HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
        if HRP then HRP.Anchored = false end
    end
    
    if Library.Toggles.SpeedEnabled.Value and Hum then
        Hum.WalkSpeed = Library.Options.WalkSpeed.Value
    end
    
    if Library.Toggles.Noclip.Value and HRP then
        if Library.Options.NoclipMode.Value == "Collision" then 
            for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() 
    getgenv().EvadeLoaded = false
    ObjectESP.Clear()
    Library:Unload() 
    Sense.Unload() 
end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/AR2")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | AR2 Loaded", 5)
