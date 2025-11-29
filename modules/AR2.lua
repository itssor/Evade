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

-- // 1. PATCH SENSE (AR2 Fix)
-- Force Sense to find characters even if AR2 hides them
if not Sense.EspInterface then
    Sense.EspInterface = {}
end

Sense.EspInterface.getCharacter = function(Player)
    if Player.Character then return Player.Character end
    -- Fallback scan for AR2 specific folders if .Character is nil
    if Workspace:FindFirstChild("Characters") then
        return Workspace.Characters:FindFirstChild(Player.Name)
    end
    return nil
end

Sense.EspInterface.getHealth = function(Character)
    local Hum = Character and Character:FindFirstChild("Humanoid")
    if Hum then return Hum.Health, Hum.MaxHealth end
    return 100, 100
end

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | AR2 (Sense)",
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
SilentGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })

local GunGroup = Tabs.Combat:AddRightGroupbox("Gun Mods")
GunGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false })
GunGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false })

-- // VISUALS (Sense + Custom)
local PlayerGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP (Sense)")
PlayerGroup:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v)
    Sense.teamSettings.enemy.enabled = v
    Sense.teamSettings.friendly.enabled = v 
    Sense.Load()
end)
PlayerGroup:AddToggle("ESPBox", { Text = "Boxes", Default = true }):OnChanged(function(v) Sense.teamSettings.enemy.box = v; Sense.teamSettings.friendly.box = v end)
PlayerGroup:AddToggle("ESPName", { Text = "Names", Default = true }):OnChanged(function(v) Sense.teamSettings.enemy.name = v; Sense.teamSettings.friendly.name = v end)
PlayerGroup:AddToggle("ESPHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v; Sense.teamSettings.friendly.healthBar = v end)
PlayerGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v; Sense.teamSettings.friendly.tracer = v end)
PlayerGroup:AddToggle("ESPDist", { Text = "Distance", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.distance = v; Sense.teamSettings.friendly.distance = v end)

local CustomVis = Tabs.Visuals:AddRightGroupbox("World ESP")
CustomVis:AddToggle("ZombieESP", { Text = "Zombies", Default = false })
CustomVis:AddToggle("MilCrate", { Text = "Military Crates", Default = false })
CustomVis:AddToggle("VehicleESP", { Text = "Vehicles", Default = false })

-- // MOVEMENT
local FlightGroup = Tabs.Movement:AddLeftGroupbox("Flight System")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed Engine")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddDropdown("SpeedMode", { Values = {"WalkSpeed", "CFrame", "TP"}, Default = 1, Multi = false, Text = "Mode" })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 16, Min = 16, Max = 300, Rounding = 0 })

local MiscMove = Tabs.Movement:AddLeftGroupbox("Misc")
MiscMove:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MiscMove:AddDropdown("NoclipMode", { Values = {"Collision", "CFrame"}, Default = 1, Text = "Noclip Mode" })
MiscMove:AddToggle("Noclip", { Text = "Noclip", Default = false })

-- // LOGIC: CUSTOM VISUALS (Zombies/Loot)
local Drawings = {}
local LootCache = {}
local ZombieCache = {}

local function CreateDraw(T, P) 
    local D=Drawing.new(T)
    for k,v in pairs(P) do D[k]=v end
    table.insert(Drawings,D)
    return D 
end

local function ScanWorld()
    if Library.Toggles.ZombieESP.Value then
        table.clear(ZombieCache)
        -- AR2 Zombies are usually in "Zombies" or "Spawns" folder
        local ZFolder = Workspace:FindFirstChild("Zombies") or Workspace:FindFirstChild("Spawns")
        if ZFolder then
            for _, z in pairs(ZFolder:GetDescendants()) do
                if z:IsA("Model") and z:FindFirstChild("HumanoidRootPart") and z:FindFirstChild("Humanoid") then
                     -- Filter out players to be safe
                    if not Services.Players:GetPlayerFromCharacter(z) then
                        table.insert(ZombieCache, {Obj = z.HumanoidRootPart, Name = "Zombie"})
                    end
                end
            end
        end
    end

    if tick() % 2 < 0.1 then -- Slow scan for loot
        table.clear(LootCache)
        if Library.Toggles.MilCrate.Value then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v.Name == "Military Crate" and v:IsA("Model") and v.PrimaryPart then
                    table.insert(LootCache, {Obj = v.PrimaryPart, Name = "Mil Crate", Color = Color3.fromRGB(0, 255, 0)})
                end
            end
        end
        if Library.Toggles.VehicleESP.Value then
            local VFolder = Workspace:FindFirstChild("Vehicles")
            if VFolder then
                for _, v in pairs(VFolder:GetChildren()) do
                    if v.PrimaryPart then
                         table.insert(LootCache, {Obj = v.PrimaryPart, Name = v.Name, Color = Color3.fromRGB(0, 100, 255)})
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do ScanWorld(); task.wait(0.5) end
end)

Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    -- Zombies
    if Library.Toggles.ZombieESP.Value then
        for _, z in pairs(ZombieCache) do
            if z.Obj and z.Obj.Parent then
                local Pos, Vis = Camera:WorldToViewportPoint(z.Obj.Position)
                if Vis then
                    CreateDraw("Text", {Visible=true, Text=z.Name, Color=Color3.fromRGB(255, 170, 0), Center=true, Outline=true, Size=13, Position=Vector2.new(Pos.X, Pos.Y)})
                end
            end
        end
    end

    -- Loot
    for _, l in pairs(LootCache) do
        if l.Obj and l.Obj.Parent then
            local Pos, Vis = Camera:WorldToViewportPoint(l.Obj.Position)
            if Vis then
                CreateDraw("Text", {Visible=true, Text=l.Name, Color=l.Color, Center=true, Outline=true, Size=13, Position=Vector2.new(Pos.X, Pos.Y)})
            end
        end
    end
end)

-- // LOGIC: SILENT AIM
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

local function GetClosest()
    local C = nil; local D = Library.Options.SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local Char = Sense.EspInterface.getCharacter(p) -- Use our patched getter
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
    if Library.Toggles.DrawSilent.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.SilentFOV.Value; FOVCircle.Color = Library.Options.SilentColor.Value; FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end
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
            -- AR2 Ballistics Override
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

-- // LOGIC: MOVEMENT & RECOIL
task.spawn(function()
    while true do
        if Library.Toggles.NoRecoil.Value then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "Recoil") then
                    v.Recoil = 0; v.Spread = 0; v.Kick = 0
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

    if Library.Toggles.FlightEnabled.Value and Library.Options.FlightKey:GetState() and HRP then
        local Mode = Library.Options.FlightMode.Value
        local Speed = Library.Options.FlightSpeed.Value
        local Dir = Vector3.zero
        
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end

        if Mode ~= "LinearVelocity" and HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
        if Mode ~= "BodyVelocity" and HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
        if Mode ~= "CFrame" then HRP.Anchored = false end

        if Mode == "LinearVelocity" then
            local LV = HRP:FindFirstChild("SWFly") or Instance.new("LinearVelocity", HRP); LV.Name = "SWFly"
            LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
            local Att = HRP:FindFirstChild("SWAtt") or Instance.new("Attachment", HRP); Att.Name = "SWAtt"; LV.Attachment0 = Att
            LV.VectorVelocity = Dir * Speed
            local BV = HRP:FindFirstChild("SWHold") or Instance.new("BodyVelocity", HRP); BV.Name = "SWHold"; BV.MaxForce = Vector3.new(0,math.huge,0); BV.Velocity = Vector3.zero
        elseif Mode == "CFrame" then
            HRP.Anchored = true
            HRP.CFrame = HRP.CFrame + (Dir * (Speed/50))
        elseif Mode == "BodyVelocity" then
            local BV = HRP:FindFirstChild("SWBV") or Instance.new("BodyVelocity", HRP); BV.Name = "SWBV"
            BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); BV.Velocity = Dir * Speed
        end
    else
        if HRP then
            if HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
            if HRP:FindFirstChild("SWHold") then HRP.SWHold:Destroy() end
            if HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
            if HRP:FindFirstChild("SWAtt") then HRP.SWAtt:Destroy() end
            HRP.Anchored = false
        end
    end
    
    if Library.Toggles.SpeedEnabled.Value and Hum then
        local Mode = Library.Options.SpeedMode.Value
        if Mode == "WalkSpeed" then Hum.WalkSpeed = Library.Options.WalkSpeed.Value
        elseif Mode == "CFrame" and HRP and Hum.MoveDirection.Magnitude > 0 then Hum.WalkSpeed = 16; HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Library.Options.WalkSpeed.Value / 100))
        elseif Mode == "TP" and HRP and Hum.MoveDirection.Magnitude > 0 then Hum.WalkSpeed = 16; HRP.CFrame = HRP.CFrame * CFrame.new(0, 0, -(Library.Options.WalkSpeed.Value / 50)) end
    else if Hum and Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end end
    
    if Library.Toggles.Noclip.Value and HRP then
        if Library.Options.NoclipMode.Value == "Collision" then for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        elseif Library.Options.NoclipMode.Value == "CFrame" and Hum.MoveDirection.Magnitude > 0 then HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * 0.5) end
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
Evade.SaveManager:SetFolder("Evade/AR2")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | AR2 Loaded", 5)
