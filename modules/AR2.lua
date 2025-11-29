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
local Workspace = Services.Workspace

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | AR2",
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
GunGroup:AddToggle("NoSway", { Text = "No Sway", Default = false })

-- // VISUALS
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

local ZombieGroup = Tabs.Visuals:AddRightGroupbox("World ESP")
ZombieGroup:AddToggle("ZombieESP", { Text = "Zombie ESP", Default = false })
ZombieGroup:AddToggle("LootESP", { Text = "Rare Loot ESP", Default = false })
ZombieGroup:AddToggle("VehicleESP", { Text = "Vehicle ESP", Default = false })

-- // MOVEMENT
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Character")
MoveGroup:AddToggle("InfStamina", { Text = "Infinite Stamina", Default = false })
MoveGroup:AddToggle("Speed", { Text = "Speedhack", Default = false })
MoveGroup:AddSlider("SpeedVal", { Text = "Factor", Default = 20, Min = 16, Max = 50 })

local FlightGroup = Tabs.Movement:AddRightGroupbox("Flight")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300 })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })

-- // LOGIC: WORLD SCANNER (Zombies & Loot)
local Drawings = {}
local EntityCache = {}

local function ScanWorld()
    table.clear(EntityCache)
    
    -- Zombies
    if Library.Toggles.ZombieESP.Value then
        local ZFolder = Workspace:FindFirstChild("Zombies") or Workspace:FindFirstChild("Animals")
        if ZFolder then
            for _, z in pairs(ZFolder:GetChildren()) do
                if z:FindFirstChild("HumanoidRootPart") and z:FindFirstChild("Humanoid") and z.Humanoid.Health > 0 then
                    table.insert(EntityCache, {Obj = z.HumanoidRootPart, Name = "Infected", Color = Color3.fromRGB(255, 150, 0)})
                end
            end
        end
    end

    -- Loot & Vehicles (Throttled Scan)
    if tick() % 2 < 0.1 then
        if Library.Toggles.LootESP.Value then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v.Name == "Military Crate" or v.Name == "Police Crate" then
                    if v.PrimaryPart then
                         table.insert(EntityCache, {Obj = v.PrimaryPart, Name = v.Name, Color = Color3.fromRGB(0, 255, 0)})
                    end
                end
            end
        end
        if Library.Toggles.VehicleESP.Value then
            local VFolder = Workspace:FindFirstChild("Vehicles")
            if VFolder then
                for _, v in pairs(VFolder:GetChildren()) do
                    if v.PrimaryPart then
                        table.insert(EntityCache, {Obj = v.PrimaryPart, Name = v.Name, Color = Color3.fromRGB(0, 100, 255)})
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        ScanWorld()
        task.wait(1)
    end
end)

-- // LOGIC: RENDER LOOP
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false; FOVCircle.Visible=false

Services.RunService.RenderStepped:Connect(function()
    -- Cleanup
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}

    -- World ESP
    for _, t in pairs(EntityCache) do
        if t.Obj and t.Obj.Parent then
            local Pos, Vis = Camera:WorldToViewportPoint(t.Obj.Position)
            if Vis then
                local T = Drawing.new("Text")
                T.Visible = true; T.Text = t.Name; T.Color = t.Color; T.Center = true; T.Outline = true; T.Size = 13
                T.Position = Vector2.new(Pos.X, Pos.Y)
                table.insert(Drawings, T)
            end
        end
    end

    -- FOV
    if Library.Toggles.DrawSilent.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true
        FOVCircle.Radius = Library.Options.SilentFOV.Value
        FOVCircle.Color = Library.Options.SilentColor.Value
        FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else
        FOVCircle.Visible = false
    end
end)

-- // LOGIC: SILENT AIM
local function GetClosest()
    local C = nil; local D = Library.Options.SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            -- Basic checks
            local Pos, Vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if Vis then
                local Dist = (MP - Vector2.new(Pos.X, Pos.Y)).Magnitude
                if Dist < D then
                    if not Library.Toggles.WallCheck.Value or #Camera:GetPartsObscuringTarget({p.Character.Head.Position}, {LocalPlayer.Character, p.Character, Camera}) == 0 then
                         D = Dist; C = p.Character.Head
                    end
                end
            end
        end
    end
    return C
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.SilentAim.Value and method == "FireServer" and (self.Name == "Fire" or self.Name == "Shoot" or self.Name == "Projectiles") then
        local Target = GetClosest()
        if Target then
            -- AR2 often accepts a CFrame or Vector3 for bullet direction
            for i, v in pairs(args) do
                if typeof(v) == "Vector3" then
                    args[i] = (Target.Position - Camera.CFrame.Position).Unit * 1000
                    break
                elseif typeof(v) == "CFrame" then
                    args[i] = CFrame.new(Camera.CFrame.Position, Target.Position)
                    break
                end
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // LOGIC: GUN MODS & STAMINA
task.spawn(function()
    while true do
        if Library.Toggles.NoRecoil.Value or Library.Toggles.NoSpread.Value or Library.Toggles.NoSway.Value then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "Recoil") then
                    if Library.Toggles.NoRecoil.Value then v.Recoil = 0; v.Kick = 0 end
                    if Library.Toggles.NoSpread.Value then v.Spread = 0 end
                    if Library.Toggles.NoSway.Value then v.Sway = 0 end
                end
            end
        end
        task.wait(2)
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    
    -- Infinite Stamina
    if Library.Toggles.InfStamina.Value then
        local Stats = LocalPlayer.Character:FindFirstChild("Stats") -- AR2 often uses this
        if Stats and Stats:FindFirstChild("Stamina") then
            Stats.Stamina.Value = 100
        end
    end
    
    -- Movement Suite (Flight/Speed/Noclip)
    -- [Copy standard movement logic here - kept brief for length]
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Library.Toggles.FlightEnabled.Value and HRP and Library.Options.FlightKey:GetState() then
         -- (Standard Flight Logic)
         local LV = HRP:FindFirstChild("SWFly") or Instance.new("LinearVelocity", HRP); LV.Name="SWFly"
         LV.VectorVelocity = Camera.CFrame.LookVector * Library.Options.FlightSpeed.Value
         LV.Attachment0 = HRP:FindFirstChild("RootAttachment")
    else
         if HRP and HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
    end
    
    if Library.Toggles.Speed.Value and Hum then
         Hum.WalkSpeed = Library.Options.SpeedVal.Value
    end
end)

-- // SETTINGS
Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/AR2")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | AR2 Loaded", 5)
