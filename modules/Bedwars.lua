local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera

-- // 1. REMOTE SNIFFER
-- Instead of hooking code, we look for the physical RemoteEvents in ReplicatedStorage
local Net = nil
local AttackRemote = nil
local DamageBlockRemote = nil

local function SniffRemotes()
    -- Wait for game to load basic assets
    local RS = Services.ReplicatedStorage
    local Node = RS:WaitForChild("rbxts_include", 10)
    if not Node then return false end
    
    local Out = Node:WaitForChild("node_modules", 10):WaitForChild("@rbxts", 10):WaitForChild("net", 10):WaitForChild("out", 10):WaitForChild("_NetManaged", 10)
    if not Out then return false end
    
    Net = Out
    
    -- Find Attack Remote (Usually has "Sword" or "Attack" in name)
    -- Bedwars changes these names, but they exist in this folder
    for _, v in pairs(Net:GetChildren()) do
        if v.Name:find("SwordHit") or v.Name:find("Attack") then
            AttackRemote = v
        elseif v.Name:find("DamageBlock") then
            DamageBlockRemote = v
        end
    end
    
    return true
end

SniffRemotes()

-- // 2. UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Bedwars (Lite)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- COMBAT
local Aura = Tabs.Combat:AddLeftGroupbox("Kill Aura")
Aura:AddToggle("Killaura", { Text = "Enabled", Default = false })
Aura:AddSlider("AuraRange", { Text = "Range", Default = 18, Min = 1, Max = 20 })
Aura:AddToggle("SwingAnim", { Text = "Visual Swing", Default = true })

local Vel = Tabs.Combat:AddRightGroupbox("Mods")
Vel:AddToggle("Velocity", { Text = "Anti-Knockback", Default = false })
Vel:AddSlider("VelH", { Text = "Horizontal %", Default = 0, Min = 0, Max = 100 })
Vel:AddSlider("VelV", { Text = "Vertical %", Default = 0, Min = 0, Max = 100 })

-- MOVEMENT
local Fly = Tabs.Movement:AddLeftGroupbox("Flight")
Fly:AddToggle("Flight", { Text = "Flight", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })
Fly:AddSlider("FlySpeed", { Text = "Speed", Default = 40, Min = 10, Max = 80 })

local Move = Tabs.Movement:AddRightGroupbox("Movement")
Move:AddToggle("Sprint", { Text = "Force Sprint", Default = true })
Move:AddToggle("Speed", { Text = "Speed", Default = false })
Move:AddSlider("SpeedVal", { Text = "Factor", Default = 20, Min = 16, Max = 35 })

-- VISUALS
local Vis = Tabs.Visuals:AddLeftGroupbox("ESP")
Vis:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
Vis:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })

-- // 3. LOGIC LOOPS

-- Helper: Find Target
local function GetTarget(Range)
    local T, D = nil, Range
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health > 0 then
                local dist = (r.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < D then D = dist; T = p.Character end
            end
        end
    end
    return T
end

-- Helper: Attack
local function Attack(Target)
    -- Swing Animation (Client side)
    if Library.Toggles.SwingAnim.Value then
        pcall(function()
            local Tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if Tool then Tool:Activate() end
        end)
    end

    -- Fire Remote directly
    if AttackRemote then
        local args = {
            ["chargedAttack"] = {["chargeRatio"] = 0},
            ["entityInstance"] = Target,
            ["validate"] = {
                ["targetPosition"] = {["value"] = Target.HumanoidRootPart.Position},
                ["selfPosition"] = {["value"] = LocalPlayer.Character.HumanoidRootPart.Position}
            }
        }
        AttackRemote:FireServer(args)
    end
end

-- Logic Loop
task.spawn(function()
    while true do
        if not LocalPlayer.Character then task.wait(); continue end
        local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        -- Killaura
        if Library.Toggles.Killaura.Value and HRP then
            local T = GetTarget(Library.Options.AuraRange.Value)
            if T then
                -- Face Target (Client only)
                HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(T.HumanoidRootPart.Position.X, HRP.Position.Y, T.HumanoidRootPart.Position.Z))
                Attack(T)
            end
        end
        
        task.wait(0.12) -- 8-9 hits per second
    end
end)

-- Physics Loop
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    -- Velocity (Anti-KB)
    if Library.Toggles.Velocity.Value and HRP then
        if HRP.Velocity.Magnitude > 20 or HRP.Velocity.Y > 10 then
             HRP.Velocity = Vector3.new(
                 HRP.Velocity.X * (Library.Options.VelH.Value/100),
                 HRP.Velocity.Y * (Library.Options.VelV.Value/100),
                 HRP.Velocity.Z * (Library.Options.VelH.Value/100)
             )
        end
    end
    
    -- Flight
    if Library.Toggles.Flight.Value and Library.Options.FlyKey:GetState() and HRP then
        local LV = HRP:FindFirstChild("VoidFly") or Instance.new("LinearVelocity", HRP); LV.Name = "VoidFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        local Att = HRP:FindFirstChild("VoidAtt") or Instance.new("Attachment", HRP); Att.Name = "VoidAtt"; LV.Attachment0 = Att
        
        local Dir = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then Dir = Dir + Vector3.new(0,1,0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Dir = Dir - Vector3.new(0,1,0) end
        
        LV.VectorVelocity = Dir * Library.Options.FlySpeed.Value
        if HRP.Position.Y < -10 then HRP.Velocity = Vector3.new(0, 50, 0) end
    else
        if HRP:FindFirstChild("VoidFly") then HRP.VoidFly:Destroy() end
    end
    
    -- Sprint
    if Library.Toggles.Sprint.Value and Hum then
        if Hum.WalkSpeed < 20 then Hum.WalkSpeed = 23 end -- Legit max speed
    end
    
    -- Speed Hack
    if Library.Toggles.Speed.Value and Hum then
        Hum.WalkSpeed = Library.Options.SpeedVal.Value
    end
end)

-- ESP Loop
local Drawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    -- Bed ESP
    if Library.Toggles.BedESP.Value then
        for _, Bed in pairs(Services.CollectionService:GetTagged("bed")) do
            if Bed and Bed:FindFirstChild("Covers") then
                local Pos, Vis = Camera:WorldToViewportPoint(Bed.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(30,30); B.Position=Vector2.new(Pos.X-15,Pos.Y-15)
                    B.Color = Bed.Covers.BrickColor.Color; B.Thickness=2; B.Filled=false; table.insert(Drawings, B)
                end
            end
        end
    end
    
    -- Player ESP
    if Library.Toggles.PlayerESP.Value then
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local Pos, Vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(2000/Pos.Z, 3000/Pos.Z); B.Position=Vector2.new(Pos.X-B.Size.X/2,Pos.Y-B.Size.Y/2)
                    B.Color = p.TeamColor.Color; B.Thickness=1; B.Filled=false; table.insert(Drawings, B)
                end
            end
        end
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().EvadeLoaded = false; Library:Unload(); Evade.Sense.Unload() end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Bedwars")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Bedwars (Lite) Loaded", 5)
